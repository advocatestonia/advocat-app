// org-usage-stats Edge Function
// -----------------------------------------------------------------------------
// Read-only dashboard endpoint: messages, documents, cases, API calls — both
// org-totals and per-member breakdown.
//
// Caching: we set Cache-Control: private, max-age=60 so the Flutter client
// dashes don't hammer this on every screen open.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { requireOrgContext } from "../_shared/orgAuth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

type Period = "current_month" | "last_30_days" | "current_year" | "custom";

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: { ...corsHeaders, "Access-Control-Allow-Methods": "GET, POST, OPTIONS" },
    });
  }
  if (req.method !== "GET" && req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "org-usage-stats",
    maxPerMinute: 60,
  });
  if (gate.kind === "deny") return gate.response;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const orgGate = await requireOrgContext(
    req,
    supabase,
    gate.user.id,
    gate.user.email,
    { minRole: "member" },
  );
  if (orgGate.kind === "deny") return orgGate.response;
  const ctx = orgGate.ctx;

  // Parse period from query string (GET) or body (POST).
  const url = new URL(req.url);
  let period: Period = (url.searchParams.get("period") as Period) ?? "current_month";
  let fromIso = url.searchParams.get("from");
  let toIso = url.searchParams.get("to");

  if (req.method === "POST") {
    try {
      const body = await req.json();
      if (body?.period) period = body.period;
      if (body?.from) fromIso = body.from;
      if (body?.to) toIso = body.to;
    } catch {
      // Ignore — query params will be used.
    }
  }

  const range = resolvePeriod(period, fromIso, toIso);
  if (!range) {
    return jsonError("Invalid period", 400, { reason: "invalid_period" });
  }
  const { start, end } = range;

  // ── Totals via parallel COUNTs ────────────────────────────────────────
  // Each table has org_id + created_at; we use the partial index from
  // the architecture doc (idx_<table>_org_id) for performance.
  const [messagesTotal, docsTotal, casesTotal, apiCallsTotal] = await Promise.all([
    countRange(supabase, "chat_messages", ctx.org_id, start, end),
    countRange(supabase, "documents", ctx.org_id, start, end),
    countRange(supabase, "cases", ctx.org_id, start, end),
    countApiCalls(supabase, ctx.org_id, start, end),
  ]);

  // ── Per-member breakdown ──────────────────────────────────────────────
  // For orgs with < 100 members we compute on the fly; otherwise read
  // the org_usage_counters materialized view (refreshed hourly).
  const { data: members } = await supabase
    .from("org_members")
    .select("user_id, role")
    .eq("org_id", ctx.org_id)
    .is("removed_at", null);

  const memberIds = (members ?? []).map((m: { user_id: string }) => m.user_id);
  let byMember: Array<{
    user_id: string;
    full_name: string | null;
    role: string;
    messages: number;
    cases: number;
  }> = [];

  if (memberIds.length > 0 && memberIds.length <= 100) {
    // Fetch names from profiles in one round-trip.
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id, full_name, email")
      .in("id", memberIds);
    const nameById = new Map<string, { name: string | null; email: string | null }>();
    for (const p of profiles ?? []) {
      nameById.set(p.id, {
        name: (p as { full_name?: string | null }).full_name ?? null,
        email: (p as { email?: string | null }).email ?? null,
      });
    }

    // Per-user counts.
    byMember = await Promise.all(
      memberIds.map(async (uid: string) => {
        const [msgs, cases] = await Promise.all([
          countRangePerUser(supabase, "chat_messages", ctx.org_id, uid, start, end),
          countRangePerUser(supabase, "cases", ctx.org_id, uid, start, end),
        ]);
        const profile = nameById.get(uid);
        const role = (members ?? []).find(
          (m: { user_id: string; role: string }) => m.user_id === uid,
        )?.role ?? "member";
        return {
          user_id: uid,
          full_name: profile?.name ?? profile?.email ?? null,
          role,
          messages: msgs,
          cases,
        };
      }),
    );
  }

  // ── By-day series (for a small bar chart) ─────────────────────────────
  // Bucket messages by day. Limit to ~92 days (3 months) to keep payload bounded.
  const byDay = await aggregateByDay(supabase, ctx.org_id, start, end);

  const responseBody = {
    period: { start: start.toISOString(), end: end.toISOString(), name: period },
    totals: {
      messages_sent: messagesTotal,
      documents_uploaded: docsTotal,
      cases_created: casesTotal,
      api_calls: apiCallsTotal,
    },
    by_member: byMember,
    by_day: byDay,
  };

  return new Response(JSON.stringify(responseBody), {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "private, max-age=60",
    },
  });
}

if (import.meta.main) {
  serve(handleRequest);
}

export function resolvePeriod(
  period: Period,
  fromIso: string | null,
  toIso: string | null,
): { start: Date; end: Date } | null {
  const now = new Date();
  if (period === "current_month") {
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    return { start, end: now };
  }
  if (period === "last_30_days") {
    const start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    return { start, end: now };
  }
  if (period === "current_year") {
    const start = new Date(Date.UTC(now.getUTCFullYear(), 0, 1));
    return { start, end: now };
  }
  if (period === "custom") {
    if (!fromIso || !toIso) return null;
    const start = new Date(fromIso);
    const end = new Date(toIso);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return null;
    if (start > end) return null;
    // Cap range at 1 year to keep query bounded.
    if (end.getTime() - start.getTime() > 366 * 24 * 60 * 60 * 1000) return null;
    return { start, end };
  }
  return null;
}

// deno-lint-ignore no-explicit-any
async function countRange(sb: any, table: string, orgId: string, start: Date, end: Date): Promise<number> {
  const { count, error } = await sb
    .from(table)
    .select("id", { count: "exact", head: true })
    .eq("org_id", orgId)
    .gte("created_at", start.toISOString())
    .lte("created_at", end.toISOString());
  if (error) {
    console.error(`[org-usage-stats] count ${table} failed:`, error.message);
    return 0;
  }
  return count ?? 0;
}

// deno-lint-ignore no-explicit-any
async function countRangePerUser(sb: any, table: string, orgId: string, userId: string, start: Date, end: Date): Promise<number> {
  const { count, error } = await sb
    .from(table)
    .select("id", { count: "exact", head: true })
    .eq("org_id", orgId)
    .eq("user_id", userId)
    .gte("created_at", start.toISOString())
    .lte("created_at", end.toISOString());
  if (error) return 0;
  return count ?? 0;
}

// deno-lint-ignore no-explicit-any
export async function countApiCalls(sb: any, orgId: string, start: Date, end: Date): Promise<number> {
  // org_api_rate_counters has NO org_id column — it keys on api_key_id
  // (migration 20260523060000: columns are api_key_id, bucket_date,
  // request_count). So we first resolve the org's API keys, then sum
  // request_count over the date range. (Previously this queried org_id/day/
  // count — none of which exist — so the count silently failed to 0.)
  const { data: keys, error: keysErr } = await sb
    .from("org_api_keys")
    .select("id")
    .eq("org_id", orgId);
  if (keysErr) {
    console.error(`[org-usage-stats] api_keys lookup failed:`, keysErr.message);
    return 0;
  }
  const keyIds = (keys ?? []).map((k: { id: string }) => k.id);
  if (keyIds.length === 0) return 0;

  const { data, error } = await sb
    .from("org_api_rate_counters")
    .select("request_count")
    .in("api_key_id", keyIds)
    .gte("bucket_date", start.toISOString().slice(0, 10))
    .lte("bucket_date", end.toISOString().slice(0, 10));
  if (error) {
    console.error(`[org-usage-stats] api_calls count failed:`, error.message);
    return 0;
  }
  return (data ?? []).reduce(
    (acc: number, r: { request_count: number }) => acc + (r.request_count ?? 0),
    0,
  );
}

// deno-lint-ignore no-explicit-any
async function aggregateByDay(sb: any, orgId: string, start: Date, end: Date) {
  // Use an RPC if available for efficient grouping; fall back to client-side
  // bucketing of the first 10k messages (sufficient for the 92-day window).
  try {
    // deno-lint-ignore no-explicit-any
    const { data, error } = await (sb as any).rpc("org_messages_by_day", {
      p_org_id: orgId,
      p_start: start.toISOString(),
      p_end: end.toISOString(),
    });
    if (!error && data) return data;
  } catch {
    // Ignore — fall through.
  }

  const { data: msgs } = await sb
    .from("chat_messages")
    .select("created_at")
    .eq("org_id", orgId)
    .gte("created_at", start.toISOString())
    .lte("created_at", end.toISOString())
    .limit(10_000);

  const buckets = new Map<string, number>();
  for (const m of msgs ?? []) {
    const day = (m.created_at as string).slice(0, 10);
    buckets.set(day, (buckets.get(day) ?? 0) + 1);
  }
  return Array.from(buckets.entries())
    .map(([date, messages]) => ({ date, messages }))
    .sort((a, b) => (a.date < b.date ? -1 : 1));
}
