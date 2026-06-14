// router.ts — EU-inference routing (Data Fortress Pillar 2: EU residency).
// ----------------------------------------------------------------------------
// Decides, per request, WHICH inference endpoint serves a payload based on the
// data-sensitivity TIER and the configured residency posture. The goal: keep
// special-category (Art. 9) legal data inside the EU for processing, while not
// breaking the product before the owner wires an EU LLM account.
//
// This is a SKELETON with a working default path and clearly-marked owner
// hooks for the EU providers. It composes with _shared/llm_egress (which
// pseudonymizes before send) — residency is the backstop for the contextual
// PII that pseudonymization deliberately keeps (names/emails).
//
// TIERS (caller declares; mirrors the egress gateway's sensitivity):
//   TIER_0  raw documents (passport scans, court PDFs via Vision). MUST NOT go
//           to a non-EU LLM in the clear. Today: routed to eu_vision if
//           configured, else BLOCKED with a descriptive error (no silent US
//           egress of a raw passport image).
//   TIER_1  sensitive case text (names + police/Migri/court facts). Prefer an
//           EU-region text model; pseudonymized first by the egress gateway.
//   TIER_2  generic legal Q&A with incidental PII. EU-preferred but the
//           current provider with a no-train DPA is acceptable.
//
// RESIDENCY posture (env EU_INFERENCE_MODE):
//   'off'        (default) — use the existing providers (US). Router is a
//                no-op pass-through; logs the would-be EU decision for audit.
//   'preferred'  — use EU endpoints when configured, else fall back to US for
//                TIER_1/2 (TIER_0 still blocked if no EU vision).
//   'strict'     — EU-only. Any tier with no EU endpoint is BLOCKED rather
//                than leaking to US. Use once EU providers are wired.
// ----------------------------------------------------------------------------

export type DataTier = "TIER_0" | "TIER_1" | "TIER_2";
export type ResidencyMode = "off" | "preferred" | "strict";

/** A resolved routing decision the caller acts on. */
export interface RouteDecision {
  /** Where to send: a named EU endpoint, the legacy US provider, or blocked. */
  target: "eu_text" | "eu_vision" | "legacy_us" | "blocked";
  /** The model id to use at that target (null when blocked). */
  model: string | null;
  /** EU region of the target, for the audit manifest (null for legacy_us). */
  region: string | null;
  /** True if the resolved target keeps data in the EU. */
  eu_resident: boolean;
  /** Why we routed this way — for the access log + debugging. */
  reason: string;
}

export interface EuInferenceConfig {
  mode: ResidencyMode;
  /** Bedrock/Mistral-EU text model id, e.g. an eu-central-1 Claude. */
  euTextModel?: string;
  euTextRegion?: string;
  /** EU vision model id for TIER_0 document OCR. */
  euVisionModel?: string;
  euVisionRegion?: string;
}

export function euConfigFromEnv(
  env: { get(k: string): string | undefined } = Deno.env
): EuInferenceConfig {
  const mode = (env.get("EU_INFERENCE_MODE") ?? "off") as ResidencyMode;
  return {
    mode,
    euTextModel: env.get("EU_TEXT_MODEL") ?? undefined,
    euTextRegion: env.get("EU_TEXT_REGION") ?? undefined,
    euVisionModel: env.get("EU_VISION_MODEL") ?? undefined,
    euVisionRegion: env.get("EU_VISION_REGION") ?? undefined,
  };
}

/**
 * Resolve where a request of [tier] should be inferred, given [legacyModel]
 * (the model the existing router already picked) and the residency config.
 *
 * Pure + deterministic — no I/O. The caller dispatches based on the returned
 * target. Never silently sends a raw document (TIER_0) to a non-EU provider.
 */
export function routeInference(
  tier: DataTier,
  legacyModel: string,
  cfg: EuInferenceConfig = euConfigFromEnv()
): RouteDecision {
  const hasEuText = Boolean(cfg.euTextModel);
  const hasEuVision = Boolean(cfg.euVisionModel);

  // ── TIER_0: raw documents. Never leak a passport image to a US LLM. ──────
  if (tier === "TIER_0") {
    if (hasEuVision) {
      return {
        target: "eu_vision",
        model: cfg.euVisionModel!,
        region: cfg.euVisionRegion ?? "eu-central-1",
        eu_resident: true,
        reason: "TIER_0 raw document → EU vision model",
      };
    }
    // No EU vision configured. In 'off' mode we currently still allow the
    // legacy path (status quo — the product works today), but we FLAG it so
    // the audit shows a raw-document US egress that must be closed. In
    // 'preferred'/'strict' we BLOCK rather than leak.
    if (cfg.mode === "off") {
      return {
        target: "legacy_us",
        model: legacyModel,
        region: null,
        eu_resident: false,
        reason:
          "TIER_0 with no EU vision + mode=off → legacy US (FLAGGED: raw " +
          "document leaves EU; wire EU_VISION_MODEL to close)",
      };
    }
    return {
      target: "blocked",
      model: null,
      region: null,
      eu_resident: false,
      reason:
        "TIER_0 raw document blocked: no EU vision model and mode!=off " +
        "(refusing to send a raw document to a non-EU LLM)",
    };
  }

  // ── TIER_1 / TIER_2: text. ───────────────────────────────────────────────
  if (cfg.mode === "off") {
    return {
      target: "legacy_us",
      model: legacyModel,
      region: null,
      eu_resident: false,
      reason: `${tier} + mode=off → legacy provider (pseudonymized by gateway)`,
    };
  }

  if (hasEuText) {
    return {
      target: "eu_text",
      model: cfg.euTextModel!,
      region: cfg.euTextRegion ?? "eu-central-1",
      eu_resident: true,
      reason: `${tier} → EU text model (${cfg.mode})`,
    };
  }

  // EU text not configured.
  if (cfg.mode === "strict") {
    return {
      target: "blocked",
      model: null,
      region: null,
      eu_resident: false,
      reason: `${tier} blocked: mode=strict and no EU text model configured`,
    };
  }
  // preferred: fall back to US (data is pseudonymized; acceptable for TIER_2,
  // and a documented compromise for TIER_1 until EU text is wired).
  return {
    target: "legacy_us",
    model: legacyModel,
    region: null,
    eu_resident: false,
    reason:
      `${tier} + mode=preferred but no EU text model → legacy US fallback ` +
      `(pseudonymized; wire EU_TEXT_MODEL to keep in EU)`,
  };
}
