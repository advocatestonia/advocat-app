// vault-upload/handler.ts — pure logic for Vault encryption-at-rest hand-off.
// -----------------------------------------------------------------------------
// Two operations:
//
//   POST  /vault-upload         — encrypt metadata + insert documents row
//   GET   /vault-upload?tag_id= — list owner's docs (decrypted file_name)
//
// The actual file bytes are uploaded by the Flutter client directly to the
// `case-documents` storage bucket BEFORE this endpoint is hit (RLS on the
// bucket gates owner access; this is the same model as the pre-encryption
// path). All this fn does is wrap `file_name` + `storage_path` server-side
// and persist the row.
//
// Pure handler — no Deno-global IO. The thin server wrapper in index.ts
// injects a `Deps` object so tests can mock Supabase.
// -----------------------------------------------------------------------------

export interface SupabaseLike {
  rpc(fn: string, params: Record<string, unknown>): Promise<{
    data: unknown;
    error: { message: string; code?: string } | null;
  }>;
  from(table: string): {
    insert(row: Record<string, unknown>): {
      select(cols: string): {
        single(): Promise<{
          data: Record<string, unknown> | null;
          error: { message: string; code?: string } | null;
        }>;
      };
    };
    select(cols: string): {
      eq(col: string, val: unknown): {
        order(col: string, opts: { ascending: boolean }): {
          limit(n: number): Promise<{
            data: Array<Record<string, unknown>> | null;
            error: { message: string } | null;
          }>;
        };
        maybeSingle(): Promise<{
          data: Record<string, unknown> | null;
          error: { message: string; code?: string } | null;
        }>;
      };
    };
  };
}

export interface Deps {
  /** Supabase service-role client used to insert encrypted rows + invoke
   *  the public.vault_encrypt_text / public.vault_decrypt_text PostgREST
   *  wrappers (which delegate to app_vault.encrypt_text/decrypt_text). */
  supabase: SupabaseLike;
  /** Caller's user id (post-JWT auth). */
  userId: string;
}

// ─── Request / response contracts ──────────────────────────────────────────

export interface VaultUploadRequest {
  file_name: string;
  storage_path: string;
  mime_type: string;
  file_size_bytes?: number;
  tag_id?: string;
  case_id?: string;
}

export interface VaultUploadSuccess {
  kind: "success";
  status: 200;
  body: {
    document_id: string;
    encrypted: true;
  };
}

export interface VaultListSuccess {
  kind: "success";
  status: 200;
  body: {
    documents: Array<{
      id: string;
      file_name: string;
      storage_path: string;
      mime_type: string;
      file_size_bytes: number | null;
      created_at: string;
      case_id: string | null;
      encrypted: boolean;
    }>;
  };
}

export interface VaultError {
  kind: "error";
  status: number;
  body: { error: string };
}

export type VaultUploadResult = VaultUploadSuccess | VaultError;
export type VaultListResult = VaultListSuccess | VaultError;

// ─── Validation ────────────────────────────────────────────────────────────

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export function validateUploadRequest(
  body: unknown,
): { ok: true; req: VaultUploadRequest } | VaultError {
  if (!body || typeof body !== "object") {
    return { kind: "error", status: 400, body: { error: "body must be JSON object" } };
  }
  const b = body as Record<string, unknown>;

  if (typeof b.file_name !== "string" || b.file_name.length === 0) {
    return { kind: "error", status: 400, body: { error: "file_name required" } };
  }
  if (b.file_name.length > 512) {
    return { kind: "error", status: 400, body: { error: "file_name too long (max 512)" } };
  }
  if (typeof b.storage_path !== "string" || b.storage_path.length === 0) {
    return { kind: "error", status: 400, body: { error: "storage_path required" } };
  }
  if (b.storage_path.length > 1024) {
    return { kind: "error", status: 400, body: { error: "storage_path too long" } };
  }
  if (typeof b.mime_type !== "string" || b.mime_type.length === 0) {
    return { kind: "error", status: 400, body: { error: "mime_type required" } };
  }
  if (b.mime_type.length > 255) {
    return { kind: "error", status: 400, body: { error: "mime_type too long" } };
  }
  if (b.tag_id !== undefined && (typeof b.tag_id !== "string" || !UUID_RE.test(b.tag_id))) {
    return { kind: "error", status: 400, body: { error: "tag_id must be uuid" } };
  }
  if (b.case_id !== undefined && b.case_id !== null) {
    if (typeof b.case_id !== "string" || !UUID_RE.test(b.case_id)) {
      return { kind: "error", status: 400, body: { error: "case_id must be uuid" } };
    }
  }
  if (b.file_size_bytes !== undefined) {
    if (typeof b.file_size_bytes !== "number" || b.file_size_bytes < 0) {
      return { kind: "error", status: 400, body: { error: "file_size_bytes must be >= 0" } };
    }
  }

  const req: VaultUploadRequest = {
    file_name: b.file_name,
    storage_path: b.storage_path,
    mime_type: b.mime_type,
  };
  if (typeof b.file_size_bytes === "number") req.file_size_bytes = b.file_size_bytes;
  if (typeof b.tag_id === "string") req.tag_id = b.tag_id;
  if (typeof b.case_id === "string") req.case_id = b.case_id;
  return { ok: true, req };
}

// ─── Upload (POST) ─────────────────────────────────────────────────────────

export async function runVaultUpload(
  rawBody: unknown,
  deps: Deps,
): Promise<VaultUploadResult> {
  const v = validateUploadRequest(rawBody);
  if (!("ok" in v)) return v;
  const req = v.req;

  // 0. Ownership check on case_id. The FK to public.cases only guarantees the
  //    case EXISTS, not that the caller owns it, and the documents RLS INSERT
  //    policy checks only `auth.uid() = user_id` — NOT that case_id belongs to
  //    the same user. Without this, a caller could pin their own document row
  //    to ANOTHER user's case_id; if any read path aggregates documents by
  //    case (case view / export), the planted row would surface inside the
  //    victim's case (forgery / phishing into someone else's matter).
  //    The supabase client here is JWT-scoped (auth.uid() == userId), so the
  //    cases_select_own RLS policy returns a row ONLY when the caller owns it.
  if (req.case_id) {
    const owned = await deps.supabase
      .from("cases")
      .select("id")
      .eq("id", req.case_id)
      .maybeSingle();
    if (owned.error) {
      console.error(`vault-upload: case ownership check failed: ${owned.error.message}`);
      return { kind: "error", status: 500, body: { error: "case_check_failed" } };
    }
    if (!owned.data) {
      // Either the case does not exist or it is not the caller's. Return 403
      // without distinguishing the two (no existence oracle for foreign cases).
      return { kind: "error", status: 403, body: { error: "case_not_owned" } };
    }
  }

  // 1. Encrypt file_name + storage_path via the per-user DEK helpers.
  const encName = await deps.supabase.rpc("vault_encrypt_text", {
    p_plaintext: req.file_name,
    p_user_id: deps.userId,
  });
  if (encName.error) {
    // Log raw DB/RPC error server-side; return a stable generic code only.
    console.error(`vault-upload: encrypt(file_name) failed: ${encName.error.message}`);
    return {
      kind: "error",
      status: 500,
      body: { error: "encrypt_failed" },
    };
  }
  const encPath = await deps.supabase.rpc("vault_encrypt_text", {
    p_plaintext: req.storage_path,
    p_user_id: deps.userId,
  });
  if (encPath.error) {
    console.error(`vault-upload: encrypt(storage_path) failed: ${encPath.error.message}`);
    return {
      kind: "error",
      status: 500,
      body: { error: "encrypt_failed" },
    };
  }

  // 2. Insert documents row. We keep file_name + storage_path as sentinels
  //    so the legacy NOT-NULL path stays valid for old clients (the
  //    constraint we relaxed in 20260527090000 still permits NULL though).
  const row: Record<string, unknown> = {
    user_id: deps.userId,
    file_name: "[encrypted]",
    storage_path: req.storage_path,  // path is needed plain too for the bucket
    encrypted_file_name: encName.data,
    encrypted_storage_path: encPath.data,
    mime_type: req.mime_type,
    file_size_bytes: req.file_size_bytes ?? 0,
  };
  if (req.case_id) row.case_id = req.case_id;

  const inserted = await deps.supabase
    .from("documents")
    .insert(row)
    .select("id")
    .single();
  if (inserted.error || !inserted.data) {
    console.error(
      `vault-upload: documents.insert failed: ${inserted.error?.message ?? "no row"}`,
    );
    return {
      kind: "error",
      status: 500,
      body: { error: "insert_failed" },
    };
  }

  const docId = inserted.data["id"] as string;

  // 3. Optional tag.
  if (req.tag_id) {
    const tagRes = await deps.supabase
      .from("vault_document_tags")
      .insert({ document_id: docId, tag_id: req.tag_id })
      .select("document_id")
      .single();
    if (tagRes.error && tagRes.error.code !== "23505") {
      // 23505 = unique_violation → re-tag same pair, fine.
      // Anything else: don't fail the upload, the row is still good. Log
      // by including a soft-error field would be a future improvement.
    }
  }

  return {
    kind: "success",
    status: 200,
    body: { document_id: docId, encrypted: true },
  };
}

// ─── List (GET) ────────────────────────────────────────────────────────────

export interface ListOptions {
  tagId?: string;
}

export async function runVaultList(
  opts: ListOptions,
  deps: Deps,
): Promise<VaultListResult> {
  // We re-use the search RPC with an empty query — it already does the
  // owner scoping, decryption, primary-tag join and 100 LIMIT.
  const r = await deps.supabase.rpc("vault_search_documents", { query: "" });
  if (r.error) {
    console.error(`vault-upload: vault_search_documents failed: ${r.error.message}`);
    return {
      kind: "error",
      status: 500,
      body: { error: "list_failed" },
    };
  }
  const rows = (r.data as Array<Record<string, unknown>> | null) ?? [];

  const filtered = opts.tagId
    ? rows.filter((row) => row["tag_id"] === opts.tagId)
    : rows;

  return {
    kind: "success",
    status: 200,
    body: {
      documents: filtered.map((row) => ({
        id: row["id"] as string,
        file_name: (row["file_name"] as string) ?? "",
        storage_path: (row["storage_path"] as string) ?? "",
        mime_type: (row["mime_type"] as string) ?? "",
        file_size_bytes: (row["file_size_bytes"] as number | null) ?? null,
        created_at: (row["created_at"] as string) ?? "",
        case_id: (row["case_id"] as string | null) ?? null,
        encrypted: Boolean(row["encrypted"]),
      })),
    },
  };
}
