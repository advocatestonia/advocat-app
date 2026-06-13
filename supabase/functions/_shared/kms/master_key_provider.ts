// master_key_provider.ts — KMS-ready master-key indirection (Data Fortress
// Pillar 1). This is the EDGE-SIDE seam that lets the owner externalize the
// envelope master key from Supabase Vault to an external EU KMS WITHOUT
// touching any encrypt/decrypt caller.
// ----------------------------------------------------------------------------
// Today the master lives in Supabase Vault (vault.decrypted_secrets) and the
// DB function app_vault.get_master_key() reads it in-process. That is fine for
// encryption-at-rest but means the master is reachable by our own DB role.
//
// To raise the bar to "the master never sits in our DB", the owner:
//   1. Creates an Ed-/AES KMS key in AWS KMS eu-central-1 (Frankfurt) or GCP
//      Cloud KMS europe-*, restricted to a dedicated IAM role.
//   2. Wraps the current app_vault master under that KMS key (one-time) and
//      stores ONLY the wrapped blob; the plaintext master never persists.
//   3. Sets the secrets KMS_PROVIDER=aws_kms_eu, KMS_KEY_ARN=..., plus the
//      IAM credentials, and flips app_vault.master_key_provider.provider to
//      'aws_kms_eu' (single DB row).
//   4. Routes the DB's get_master_key() through an edge call that uses
//      unwrapMaster() below to KMS-Decrypt the wrapped master per request
//      (cached briefly in-isolate). The encrypt/decrypt RPC contract does NOT
//      change — only WHERE the master comes from.
//
// This module ships the provider abstraction + a working no-op path so the
// code compiles and tests run today; the AWS/GCP branches are clearly marked
// TODO(owner) and throw a descriptive error until wired. The AWS account is
// owner-gated; the seam is ready now.
// ----------------------------------------------------------------------------

export type KmsProvider = "supabase_vault" | "aws_kms_eu" | "gcp_kms_eu";

export interface KmsConfig {
  provider: KmsProvider;
  keyRef?: string; // KMS key ARN / resource id
  region?: string;
}

/** Read the configured provider from env (mirrors the DB registry row). */
export function kmsConfigFromEnv(
  env: { get(k: string): string | undefined } = Deno.env
): KmsConfig {
  const provider = (env.get("KMS_PROVIDER") ?? "supabase_vault") as KmsProvider;
  return {
    provider,
    keyRef: env.get("KMS_KEY_ARN") ?? env.get("KMS_KEY_REF") ?? undefined,
    region: env.get("KMS_REGION") ?? undefined,
  };
}

export class KmsNotConfiguredError extends Error {
  constructor(provider: KmsProvider) {
    super(
      `KMS provider '${provider}' selected but not wired. ` +
        `Set KMS_KEY_ARN + IAM creds and implement the ${provider} branch ` +
        `in master_key_provider.unwrapMaster (owner task).`
    );
    this.name = "KmsNotConfiguredError";
  }
}

/**
 * Unwrap the envelope master key for the configured provider.
 *
 * - 'supabase_vault': returns null to signal "let the DB read it from
 *   vault.decrypted_secrets as today" (the in-DB path is unchanged).
 * - 'aws_kms_eu' / 'gcp_kms_eu': KMS-Decrypt the wrapped master blob and
 *   return the plaintext master (base64). TODO(owner) — throws until wired.
 *
 * Returning null for the default keeps the current behaviour intact: callers
 * that get null simply use the existing DB get_master_key() path.
 */
export async function unwrapMaster(
  wrappedMasterB64: string | null,
  cfg: KmsConfig = kmsConfigFromEnv()
): Promise<string | null> {
  switch (cfg.provider) {
    case "supabase_vault":
      return null; // DB path unchanged; no external unwrap.

    case "aws_kms_eu": {
      if (!cfg.keyRef || !wrappedMasterB64)
        throw new KmsNotConfiguredError(cfg.provider);
      // TODO(owner): call AWS KMS Decrypt (eu-central-1) with the IAM role.
      //   const aws = new KMSClient({ region: cfg.region ?? "eu-central-1" });
      //   const out = await aws.send(new DecryptCommand({
      //     CiphertextBlob: base64ToBytes(wrappedMasterB64),
      //     KeyId: cfg.keyRef,
      //   }));
      //   return bytesToBase64(out.Plaintext);
      throw new KmsNotConfiguredError(cfg.provider);
    }

    case "gcp_kms_eu": {
      if (!cfg.keyRef || !wrappedMasterB64)
        throw new KmsNotConfiguredError(cfg.provider);
      // TODO(owner): call GCP Cloud KMS decrypt (europe-*) with the SA creds.
      throw new KmsNotConfiguredError(cfg.provider);
    }

    default:
      throw new KmsNotConfiguredError(cfg.provider);
  }
}

/**
 * True when an external KMS is configured (not the default in-DB Vault path).
 * Lets callers decide whether to route the master through unwrapMaster().
 */
export function usesExternalKms(cfg: KmsConfig = kmsConfigFromEnv()): boolean {
  return cfg.provider !== "supabase_vault";
}
