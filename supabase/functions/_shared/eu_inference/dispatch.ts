// dispatch.ts — execute an EU-inference RouteDecision (Data Fortress Pillar 2).
// ----------------------------------------------------------------------------
// Given a RouteDecision from router.ts, either calls the configured EU
// provider or signals the caller to use its existing (legacy) path. The EU
// provider branches are scaffolded with clear owner TODOs — the AWS Bedrock /
// Mistral-EU account is owner-gated, so until it's wired these branches throw
// a descriptive error and the router's 'off'/'preferred' modes keep the
// product working via the legacy path.
// ----------------------------------------------------------------------------

import type { RouteDecision } from "./router.ts";

export class EuProviderNotWiredError extends Error {
  constructor(target: string) {
    super(
      `EU inference target '${target}' selected but not wired. Set the EU_* ` +
        `secrets + IAM creds and implement the ${target} branch in ` +
        `eu_inference/dispatch.callEuProvider (owner task).`
    );
    this.name = "EuProviderNotWiredError";
  }
}

export class EuInferenceBlockedError extends Error {
  constructor(reason: string) {
    super(`EU inference blocked: ${reason}`);
    this.name = "EuInferenceBlockedError";
  }
}

export interface EuCallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
  region: string;
  model: string;
}

/**
 * Call the EU provider named by [decision]. Returns null when the decision
 * says to use the legacy path (target === 'legacy_us'), so the caller can fall
 * through to its existing provider chain unchanged. Throws when blocked or
 * when an EU target is selected but not yet wired.
 */
export async function callEuProvider(
  decision: RouteDecision,
  // The already-pseudonymized, Anthropic-shaped body the caller would have
  // sent. Passed through to the EU provider with the model swapped.
  // deno-lint-ignore no-explicit-any
  body: any,
  env: { get(k: string): string | undefined } = Deno.env
): Promise<EuCallResult | null> {
  switch (decision.target) {
    case "legacy_us":
      // Caller uses its existing path; nothing to do here.
      return null;

    case "blocked":
      throw new EuInferenceBlockedError(decision.reason);

    case "eu_text": {
      // TODO(owner): call Bedrock Claude (eu-central-1) or Mistral-EU with the
      // pseudonymized body + decision.model. Example (Bedrock):
      //   const aws = new BedrockRuntimeClient({ region: decision.region });
      //   const out = await aws.send(new InvokeModelCommand({
      //     modelId: decision.model,
      //     body: JSON.stringify(toBedrockMessages(body)),
      //   }));
      //   return mapBedrockResponse(out, decision);
      void body;
      void env;
      throw new EuProviderNotWiredError(decision.target);
    }

    case "eu_vision": {
      // TODO(owner): call an EU-region vision model for TIER_0 OCR. Same
      // dispatch shape; the body carries the base64 image block.
      void body;
      void env;
      throw new EuProviderNotWiredError(decision.target);
    }

    default:
      throw new EuInferenceBlockedError(`unknown target ${decision.target}`);
  }
}
