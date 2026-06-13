// master_key_provider_test.ts — KMS-ready seam behaviour.
import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  kmsConfigFromEnv,
  KmsNotConfiguredError,
  unwrapMaster,
  usesExternalKms,
} from "../master_key_provider.ts";

Deno.test("KMS-01 — default provider is supabase_vault, not external", () => {
  const cfg = kmsConfigFromEnv({ get: () => undefined });
  assertEquals(cfg.provider, "supabase_vault");
  assertEquals(usesExternalKms(cfg), false);
});

Deno.test(
  "KMS-02 — supabase_vault unwrap returns null (DB path unchanged)",
  async () => {
    const out = await unwrapMaster(null, { provider: "supabase_vault" });
    assertEquals(out, null);
  }
);

Deno.test(
  "KMS-03 — aws_kms_eu reads config from env + is flagged external",
  () => {
    const cfg = kmsConfigFromEnv({
      get: (k) =>
        ({
          KMS_PROVIDER: "aws_kms_eu",
          KMS_KEY_ARN: "arn:aws:kms:eu-central-1:1:key/abc",
          KMS_REGION: "eu-central-1",
        }[k]),
    });
    assertEquals(cfg.provider, "aws_kms_eu");
    assertEquals(cfg.keyRef, "arn:aws:kms:eu-central-1:1:key/abc");
    assert(usesExternalKms(cfg));
  }
);

Deno.test(
  "KMS-04 — aws_kms_eu unwrap throws KmsNotConfiguredError until wired",
  async () => {
    await assertRejects(
      () =>
        unwrapMaster("d2hhdGV2ZXI=", {
          provider: "aws_kms_eu",
          keyRef: "arn:...",
          region: "eu-central-1",
        }),
      KmsNotConfiguredError
    );
  }
);
