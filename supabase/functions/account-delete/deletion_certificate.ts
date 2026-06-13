// deletion_certificate.ts — sign + record a crypto-proof of Art. 17 erasure.
// ----------------------------------------------------------------------------
// Data Fortress Pillar 3 (2026-06-13). After a user is erased we record a
// signed certificate: WHAT was deleted (table -> row count), WHEN, a content
// hash, and an Ed25519 signature over that hash. The certificate is returned
// to the caller (and can be emailed) so the user has durable, independently-
// verifiable proof their data was destroyed — not a "we deleted it, trust us".
//
// Verification (anyone, offline): fetch the published public key from
// /.well-known/advocat-deletion-key.pub, recompute sha256 over
// (user_id|deleted_at|deleted_counts), and verify the Ed25519 signature.
//
// Key handling: the private key (Ed25519, base64 PKCS#8) lives in
// DELETION_SIGNING_KEY (Supabase secret / Vault). If unset, the cert is still
// recorded with its content hash but signature=null — the receipt remains
// useful (hash-anchored, append-only table) and the owner can enable signing
// by setting the secret. Signing never blocks or fails the deletion.
// ----------------------------------------------------------------------------

export interface DeletionCounts {
  [resource: string]: number;
}

export interface DeletionCertificate {
  id: string;
  content_hash: string;
  deleted_at: string;
  signature: string | null;
  signing_key_id: string | null;
}

const SIGNING_KEY_ID = "advocat-del-ed25519-v1";

/** Minimal shape of the supabase admin client we need (RPC only). */
export interface CertRpcClient {
  rpc(
    fn: string,
    args: Record<string, unknown>
  ): Promise<{ data: unknown; error: unknown }>;
}

/**
 * Sign [contentHash] (hex) with the Ed25519 private key in
 * DELETION_SIGNING_KEY (base64 PKCS#8). Returns base64 signature, or null if
 * no key is configured or signing fails (best-effort, never throws).
 */
export async function signContentHash(
  contentHash: string,
  env: { get(k: string): string | undefined } = Deno.env
): Promise<string | null> {
  const b64 = env.get("DELETION_SIGNING_KEY");
  if (!b64) return null;
  try {
    const pkcs8 = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
    const key = await crypto.subtle.importKey(
      "pkcs8",
      pkcs8,
      { name: "Ed25519" },
      false,
      ["sign"]
    );
    const sig = await crypto.subtle.sign(
      "Ed25519",
      key,
      new TextEncoder().encode(contentHash)
    );
    return btoa(String.fromCharCode(...new Uint8Array(sig)));
  } catch (e) {
    console.warn(`[del-cert] signing failed: ${String(e).slice(0, 160)}`);
    return null;
  }
}

/**
 * Record a deletion certificate for [userId]. Calls the DB to insert +
 * content-hash, then signs the returned hash and patches the signature back
 * in via a second record (the DB fn is append-only, so we sign BEFORE the
 * insert when possible). Returns the certificate, or null on failure — a cert
 * failure must NEVER block or fail the erasure itself.
 *
 * Flow: compute counts -> compute the SAME content hash the DB will -> sign
 * it -> single insert with the signature. We mirror the DB hash formula here
 * so the signature covers exactly the stored hash.
 */
export async function recordDeletionCertificate(
  sb: CertRpcClient,
  opts: {
    userId: string;
    subjectEmail: string | null;
    counts: DeletionCounts;
    deletedAt: string; // ISO; MUST match what the DB stores
    env?: { get(k: string): string | undefined };
  }
): Promise<DeletionCertificate | null> {
  try {
    const countsJson = JSON.stringify(opts.counts);
    // Canonical content hash — the edge fn owns this (it signs the SAME bytes).
    // The DB stores this value verbatim (it does not recompute), so JS-vs-
    // Postgres formatting can't diverge:
    //   sha256( user_id | deleted_at(ISO) | JSON.stringify(counts) )
    const contentHash = await sha256Hex(
      `${opts.userId}|${opts.deletedAt}|${countsJson}`
    );
    const signature = await signContentHash(contentHash, opts.env ?? Deno.env);

    const { data, error } = await sb.rpc("record_deletion_certificate", {
      p_user_id: opts.userId,
      p_subject_email: opts.subjectEmail,
      p_deleted_at: opts.deletedAt,
      p_content_hash: contentHash,
      p_deleted_counts: opts.counts,
      p_signature: signature,
      p_signing_key_id: signature ? SIGNING_KEY_ID : null,
    });
    if (error) {
      console.warn(
        `[del-cert] rpc error: ${JSON.stringify(error).slice(0, 200)}`
      );
      return null;
    }
    const row = Array.isArray(data) ? data[0] : data;
    const r = row as {
      id?: string;
      content_hash?: string;
      deleted_at?: string;
    };
    return {
      id: r?.id ?? "",
      content_hash: r?.content_hash ?? contentHash,
      deleted_at: r?.deleted_at ?? opts.deletedAt,
      signature,
      signing_key_id: signature ? SIGNING_KEY_ID : null,
    };
  } catch (e) {
    console.warn(`[del-cert] record failed: ${String(e).slice(0, 160)}`);
    return null;
  }
}

/**
 * Build the {resource: count} map from the account-delete result shape.
 * Exported so the caller (and tests) get a consistent counts object.
 */
export function buildDeletionCounts(result: {
  table_results: ReadonlyArray<{
    table: string;
    deleted?: number;
    ok: boolean;
  }>;
  storage_results: ReadonlyArray<{ bucket: string; removed: number }>;
  auth_user_deleted?: boolean;
}): DeletionCounts {
  const counts: DeletionCounts = {};
  for (const t of result.table_results) {
    if (t.ok && typeof t.deleted === "number" && t.deleted > 0) {
      counts[`table:${t.table}`] = t.deleted;
    }
  }
  for (const s of result.storage_results) {
    if (s.removed > 0) counts[`storage:${s.bucket}`] = s.removed;
  }
  if (result.auth_user_deleted) counts["auth_user"] = 1;
  return counts;
}

async function sha256Hex(s: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(s)
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
