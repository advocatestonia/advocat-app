// share-result/index.ts — HTTP entry for the "Share this analysis" feature.
// -----------------------------------------------------------------------------
// POST /share-result          — authenticated; create a public share for the
//                               caller's owned source row.
// GET  /share-result?slug=... — public; serve the marketing-safe preview.
//                               This endpoint accepts anon traffic but is
//                               rate-limited by IP.
//
// All business logic lives in handler.ts. This file is a thin shim that
// wires the Supabase admin client + the redactor into the pure handler.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { redactForSharing } from "../_shared/redactor.ts";
import {
  isValidSlug,
  type PublicShareView,
  runCreateShare,
  runReadShare,
  type ShareDbClient,
  type SourceSnapshot,
  type SourceType,
  validateCreateRequest,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("CLAUDE_API_KEY") ??
  Deno.env.get("ANTHROPIC_API_KEY");
const PUBLIC_BASE_URL = Deno.env.get("ADVOCAT_PUBLIC_BASE_URL") ??
  "https://advocat.ee";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method === "GET") return handleGet(req);
  if (req.method === "POST") return handlePost(req);
  return jsonError("Method not allowed", 405);
});

// ─── GET — public preview ──────────────────────────────────────────────────

async function handleGet(req: Request): Promise<Response> {
  // Per-IP rate limit. We allow anon traffic because the public page can
  // be hit by anyone clicking a shared link.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "share-result-read",
    maxPerMinute: 60,
    anonymousPerMinute: 60,
  });
  if (gate.kind === "deny") return gate.response;

  const url = new URL(req.url);
  const slug = url.searchParams.get("slug");
  if (!isValidSlug(slug)) {
    return jsonError("Share not found", 404);
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
  const db = buildDbClient(sb);

  const result = await runReadShare({ slug: slug!, db });
  if (result.kind === "error") {
    return jsonError(result.body.error, result.status);
  }
  return jsonOk(result.body);
}

// ─── POST — create share ───────────────────────────────────────────────────

async function handlePost(req: Request): Promise<Response> {
  const gate = await requireUserWithRateLimit(req, {
    bucket: "share-result-create",
    maxPerMinute: 10,
    // No anonymousPerMinute — share creation requires a real user JWT.
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  if (userId.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }

  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  const parsed = validateCreateRequest(raw);
  if (!parsed.ok) {
    return jsonError(parsed.error, 400);
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
  const db = buildDbClient(sb);

  try {
    const result = await runCreateShare({
      userId,
      request: parsed.value,
      db,
      publicBaseUrl: PUBLIC_BASE_URL,
      redactor: async (o) =>
        await redactForSharing({
          rawText: o.rawText,
          sourceType: o.sourceType,
          anthropicApiKey: ANTHROPIC_API_KEY,
        }),
    });
    if (result.kind === "success") return jsonOk(result.body, 200);
    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[share-result] unhandled:", e);
    return jsonError("Internal error", 500);
  }
}

// ─── DB binding ────────────────────────────────────────────────────────────

// We sidestep the @supabase/supabase-js generic types here (same pattern as
// contract-review/index.ts).
// deno-lint-ignore no-explicit-any
type AdminClient = any;

function buildDbClient(sb: AdminClient): ShareDbClient {
  return {
    async fetchSource(
      sourceType: SourceType,
      sourceId: string,
    ): Promise<SourceSnapshot | null> {
      switch (sourceType) {
        case "contract_review": {
          // contract_reviews.summary + email_md is the redaction input.
          const { data } = await sb
            .from("contract_reviews")
            .select("user_id, summary, email_md, raw_output")
            .eq("id", sourceId)
            .maybeSingle();
          if (!data) return null;
          const summary = (data.summary as string | null) ?? "";
          const emailMd = (data.email_md as string | null) ?? "";
          const raw = data.raw_output as Record<string, unknown> | null;
          // Include the most useful structured bits if raw_output is present.
          const rawBlock = raw ? JSON.stringify(raw).slice(0, 6000) : "";
          const rawText = [summary, emailMd, rawBlock]
            .filter((s) => s && s.trim().length > 0)
            .join("\n\n");
          return {
            ownerId: data.user_id as string,
            rawText,
          };
        }
        case "legal_advice": {
          // Chat AI replies live in public.chat_messages and carry their
          // own user_id (no join needed). The id is a real UUID — the
          // edge fn rejects synthetic ids like 'ai_stream_<ts>' via the
          // earlier UUID regex check in validateCreateRequest.
          const { data } = await sb
            .from("chat_messages")
            .select("content, user_id")
            .eq("id", sourceId)
            .maybeSingle();
          if (!data) return null;
          return {
            ownerId: data.user_id as string,
            rawText: (data.content as string | null) ?? "",
          };
        }
        case "deadline_analysis": {
          const { data } = await sb
            .from("case_deadlines")
            .select(
              "user_id, title, description, statute_basis, deadline_at, priority, holiday_shift_note",
            )
            .eq("id", sourceId)
            .maybeSingle();
          if (!data) return null;
          const parts = [
            (data.title as string | null) ?? "",
            (data.description as string | null) ?? "",
            (data.holiday_shift_note as string | null) ?? "",
            data.statute_basis ? `Statute: ${data.statute_basis}` : "",
            data.deadline_at ? `Deadline: ${data.deadline_at}` : "",
            data.priority ? `Priority: ${data.priority}` : "",
          ].filter((s) => s.trim().length > 0);
          return {
            ownerId: data.user_id as string,
            rawText: parts.join("\n"),
          };
        }
      }
    },

    async insertShare(row): Promise<
      { id: string; created_at: string; expires_at: string }
    > {
      const { data, error } = await sb
        .from("shared_results")
        .insert({
          user_id: row.user_id,
          share_slug: row.share_slug,
          source_type: row.source_type,
          source_id: row.source_id,
          title: row.title,
          insight_summary: row.insight_summary,
          jurisdiction: row.jurisdiction,
          case_type: row.case_type,
          redacted_content: row.redacted_content,
          og_image_url: row.og_image_url,
        })
        .select("id, created_at, expires_at")
        .single();
      if (error || !data) {
        throw new Error(
          `insert shared_results failed: ${error?.message ?? "no data"}`,
        );
      }
      return {
        id: data.id as string,
        created_at: data.created_at as string,
        expires_at: data.expires_at as string,
      };
    },

    async bumpViewCount(slug: string): Promise<void> {
      // Atomic increment via RPC would be cleaner; for now a read-modify-write
      // is acceptable (best-effort, swallowed errors).
      const { data } = await sb
        .from("shared_results")
        .select("view_count")
        .eq("share_slug", slug)
        .maybeSingle();
      if (!data) return;
      const next = ((data.view_count as number | null) ?? 0) + 1;
      await sb
        .from("shared_results")
        .update({ view_count: next })
        .eq("share_slug", slug);
    },

    async fetchPublicShare(slug: string): Promise<PublicShareView | null> {
      const { data } = await sb
        .from("shared_results")
        .select(
          "share_slug, title, insight_summary, jurisdiction, case_type, source_type, redacted_content, og_image_url, view_count, created_at, expires_at",
        )
        .eq("share_slug", slug)
        .eq("is_public", true)
        .gt("expires_at", new Date().toISOString())
        .maybeSingle();
      if (!data) return null;
      const rc = (data.redacted_content as
        | {
          bullets?: unknown;
          risks?: unknown;
          statute_refs?: unknown;
          monetary_amounts?: unknown;
        }
        | null) ?? {};
      const toArr = (x: unknown): string[] =>
        Array.isArray(x) ? x.filter((v) => typeof v === "string") as string[] : [];
      return {
        slug: data.share_slug as string,
        title: data.title as string,
        insight_summary: data.insight_summary as string,
        jurisdiction: (data.jurisdiction as string | null) ?? null,
        case_type: (data.case_type as string | null) ?? null,
        source_type: data.source_type as SourceType,
        bullets: toArr(rc.bullets),
        risks: toArr(rc.risks),
        statute_refs: toArr(rc.statute_refs),
        monetary_amounts: toArr(rc.monetary_amounts),
        og_image_url: (data.og_image_url as string | null) ?? null,
        view_count: (data.view_count as number | null) ?? 0,
        created_at: data.created_at as string,
        expires_at: data.expires_at as string,
      };
    },
  };
}
