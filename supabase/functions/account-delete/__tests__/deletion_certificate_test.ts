// deletion_certificate_test.ts — regression-lock the Pillar-3 erasure cert.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildDeletionCounts,
  recordDeletionCertificate,
  signContentHash,
} from "../deletion_certificate.ts";

Deno.test("CERT-01 — buildDeletionCounts maps tables, storage, auth", () => {
  const counts = buildDeletionCounts({
    table_results: [
      { table: "chat_messages", deleted: 12, ok: true }, // real count
      { table: "case_files", ok: true }, // no count -> presence (1)
      { table: "was_skipped", ok: true, skipped: true }, // omitted
      { table: "failed", ok: false }, // omitted
    ],
    storage_results: [
      { bucket: "case-documents", removed: 4 },
      { bucket: "empty", removed: 0 },
    ],
    auth_user_deleted: true,
  });
  // Real count preserved; cleared-without-count recorded as presence (1).
  assertEquals(counts["table:chat_messages"], 12);
  assertEquals(counts["table:case_files"], 1);
  assertEquals(counts["storage:case-documents"], 4);
  assertEquals(counts["auth_user"], 1);
  // skipped / failed / empty-bucket entries are omitted
  assert(!("table:was_skipped" in counts));
  assert(!("table:failed" in counts));
  assert(!("storage:empty" in counts));
});

Deno.test(
  "CERT-02 — signContentHash returns null when no key configured",
  async () => {
    const sig = await signContentHash("deadbeef", { get: () => undefined });
    assertEquals(sig, null);
  }
);

Deno.test(
  "CERT-03 — signContentHash signs + the signature verifies",
  async () => {
    // Generate an Ed25519 keypair, export the private key as base64 PKCS#8,
    // sign via the module, then verify with the public key.
    const kp = (await crypto.subtle.generateKey({ name: "Ed25519" }, true, [
      "sign",
      "verify",
    ])) as CryptoKeyPair;
    const pkcs8 = new Uint8Array(
      await crypto.subtle.exportKey("pkcs8", kp.privateKey)
    );
    const b64 = btoa(String.fromCharCode(...pkcs8));

    const hash = "a".repeat(64);
    const sig = await signContentHash(hash, { get: () => b64 });
    assert(sig !== null, "expected a signature");

    const sigBytes = Uint8Array.from(atob(sig!), (c) => c.charCodeAt(0));
    const ok = await crypto.subtle.verify(
      "Ed25519",
      kp.publicKey,
      sigBytes,
      new TextEncoder().encode(hash)
    );
    assert(ok, "signature did not verify against the public key");
  }
);

Deno.test(
  "CERT-04 — recordDeletionCertificate passes deleted_at + content_hash to RPC",
  async () => {
    let captured: Record<string, unknown> | null = null;
    const fakeSb = {
      rpc: (_fn: string, args: Record<string, unknown>) => {
        captured = args;
        return Promise.resolve({
          data: [
            {
              id: "cert-1",
              content_hash: args.p_content_hash,
              deleted_at: args.p_deleted_at,
            },
          ],
          error: null,
        });
      },
    };
    const cert = await recordDeletionCertificate(fakeSb, {
      userId: "u-1",
      subjectEmail: "a@b.com",
      counts: { "table:chat_messages": 2 },
      deletedAt: "2026-06-13T00:00:00.000Z",
      env: { get: () => undefined }, // no signing key -> signature null
    });
    assert(cert !== null);
    assertEquals(cert!.id, "cert-1");
    assertEquals(cert!.signature, null);
    // The RPC got the canonical hash + the SAME deleted_at we hashed over.
    assert(captured !== null);
    assertEquals(captured!["p_deleted_at"], "2026-06-13T00:00:00.000Z");
    assertEquals(typeof captured!["p_content_hash"], "string");
    assertEquals((captured!["p_content_hash"] as string).length, 64);
  }
);

Deno.test(
  "CERT-05 — cert recording never throws on RPC error (returns null)",
  async () => {
    const fakeSb = {
      rpc: () => Promise.resolve({ data: null, error: { message: "db down" } }),
    };
    const cert = await recordDeletionCertificate(fakeSb, {
      userId: "u-1",
      subjectEmail: null,
      counts: {},
      deletedAt: "2026-06-13T00:00:00.000Z",
      env: { get: () => undefined },
    });
    assertEquals(cert, null);
  }
);
