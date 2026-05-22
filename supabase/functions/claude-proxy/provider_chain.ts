// =============================================================================
// provider_chain.ts — top-to-bottom provider fallback chain (FIX-WAVE 15).
// =============================================================================
//
// Ties FIX 13 (model_router) + FIX 14 (providers/*) together. Single entry
// point `callWithFallback(signals, params, ragOnlyText)` that:
//
//   1. Asks the model router which tier to start at (Sonnet vs Haiku).
//   2. Builds an attempt sequence based on that choice + signals (anon-only
//      callers never burn Sonnet credits).
//   3. Walks the chain top-to-bottom:
//
//        Sonnet (anthropic) → Haiku (anthropic) → GPT-4o-mini (openai) → RAG-only
//
//   4. On each provider error:
//        - 429 / credit_exhausted  → record, drop one tier
//        - 5xx                     → wait 200 ms, retry once, then drop
//        - auth (401/403)          → loud log, drop without retry
//        - other 4xx               → drop without retry
//        - timeout (>25s)          → treat as failure, drop
//   5. Returns the first successful response plus a full `fallback_chain`
//      trace so the caller can persist it to telemetry / show the routing
//      reason in the response payload.
//   6. If every provider fails → returns RAG-only fallback text (status 200,
//      provider='rag_only').
//
// ENV overrides (panic switches):
//   DISABLE_OPENAI_FALLBACK=1   → never try OpenAI tier (e.g. key revoked)
//   DISABLE_HAIKU_FALLBACK=1    → emergency skip Haiku
//   RAG_ONLY_MODE=1             → don't call any provider, return ragOnlyText
//                                  immediately (full panic switch)
//
// Structured log on every attempt (greppable in Supabase logs):
//   [chain] { provider, status, latency_ms, fallback_chain }
//
// NOTE: This file IMPORTS from `./model_router.ts` (FIX 13, already in repo)
//       and `../_shared/providers/{anthropic,openai,types}_provider.ts`
//       (FIX 14, running in a parallel worktree). At time of writing FIX 14
//       has NOT landed in this worktree — `deno check` will surface unresolved
//       imports until the morning merge. That is expected and intentional.
// =============================================================================

import {
  HAIKU_MODEL_ID,
  type RoutingSignals,
  selectModel,
  SONNET_MODEL_ID,
} from "./model_router.ts";

// FIX 14 exports — these live in a parallel worktree and will resolve at the
// morning merge. Imports are written against the spec'd surface area.
import { callAnthropic } from "../_shared/providers/anthropic_provider.ts";
import { callOpenAI } from "../_shared/providers/openai_provider.ts";
import {
  Provider429Error,
  ProviderAuthError,
  ProviderCreditExhaustedError,
  ProviderError,
  ProviderTimeoutError,
} from "../_shared/providers/types.ts";

// FIX-WAVE 19 — record per-provider spend on every chain success.
// C5 burst probe found OpenAI fallback was completely unmetered, so the
// daily-cap defence (checkDailyCap) could not stop runaway OpenAI bills.
// recordSpend writes one row per call into anthropic_daily_spend with the
// correct provider tag, and the DB RPC applies tier-specific pricing.
import {
  recordSpend,
  type SpendProvider,
} from "../_shared/spend_tracker.ts";

// -----------------------------------------------------------------------------
// Public types
// -----------------------------------------------------------------------------

export type ChainProvider =
  | "anthropic_sonnet"
  | "anthropic_haiku"
  | "openai_gpt4o_mini"
  | "rag_only";

export interface ChainResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
  provider: ChainProvider;
  routing_reason: string;
  /** Ordered trace of every attempt — e.g.
   *  `["sonnet:429", "haiku:5xx", "openai:ok"]`. Always non-empty. */
  fallback_chain: string[];
}

export interface ChainParams {
  systemPrompt: string;
  messages: Array<{ role: string; content: string }>;
  maxTokens: number;
}

// -----------------------------------------------------------------------------
// Tunables
// -----------------------------------------------------------------------------

/** Hard per-provider timeout. Above this we abort and drop to next tier. */
export const PROVIDER_TIMEOUT_MS = 25_000;

/** Backoff on transient 5xx before the single same-provider retry. */
export const RETRY_5XX_BACKOFF_MS = 200;

/** Canonical OpenAI fallback model id. Cheap + fast. */
export const OPENAI_FALLBACK_MODEL = "gpt-4o-mini";

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function envFlag(name: string): boolean {
  try {
    // deno-lint-ignore no-explicit-any
    const v = (globalThis as any).Deno?.env?.get?.(name);
    if (!v) return false;
    const s = String(v).trim().toLowerCase();
    return s === "1" || s === "true" || s === "yes" || s === "on";
  } catch {
    return false;
  }
}

function logChain(entry: {
  provider: string;
  status: string;
  latency_ms: number;
  fallback_chain: string[];
  detail?: string;
}): void {
  try {
    console.log("[chain]", JSON.stringify(entry));
  } catch {
    // never let logging crash the chain
  }
}

/** Race a promise against a timeout. Throws ProviderTimeoutError on timeout
 *  so the classifier maps it to the dedicated `:timeout` chain token. */
async function withTimeout<T>(
  p: Promise<T>,
  ms: number,
  provider: string,
): Promise<T> {
  let to: number | undefined;
  const timer = new Promise<never>((_, reject) => {
    to = setTimeout(
      () => {
        const err = new ProviderTimeoutError();
        err.message = `${provider} timed out after ${ms}ms`;
        reject(err);
      },
      ms,
    ) as unknown as number;
  });
  try {
    return await Promise.race([p, timer]);
  } finally {
    if (to !== undefined) clearTimeout(to);
  }
}

// -----------------------------------------------------------------------------
// Attempt-sequence planner
// -----------------------------------------------------------------------------

type Tier = "sonnet" | "haiku" | "openai";

/** Build the ordered tier sequence based on initial router choice + signals.
 *  Anon callers (cost protection) never try Sonnet. ENV switches can prune
 *  Haiku or OpenAI. */
export function buildAttemptSequence(
  initial: "haiku" | "sonnet",
  signals: RoutingSignals,
  flags: {
    disableHaiku: boolean;
    disableOpenAI: boolean;
  },
): Tier[] {
  const seq: Tier[] = [];

  // Anon never touches Sonnet — even if router somehow recommended it.
  const startAtSonnet = initial === "sonnet" && !signals.isAnon;

  if (startAtSonnet) seq.push("sonnet");
  if (!flags.disableHaiku) seq.push("haiku");
  if (!flags.disableOpenAI) seq.push("openai");

  // Defensive: if everything was filtered out, at least try Haiku.
  if (seq.length === 0) seq.push("haiku");
  return seq;
}

function tierLabel(t: Tier): string {
  switch (t) {
    case "sonnet":
      return "sonnet";
    case "haiku":
      return "haiku";
    case "openai":
      return "openai";
  }
}

function tierToChainProvider(t: Tier): ChainProvider {
  switch (t) {
    case "sonnet":
      return "anthropic_sonnet";
    case "haiku":
      return "anthropic_haiku";
    case "openai":
      return "openai_gpt4o_mini";
  }
}

/** Model id passed to recordSpend so the DB RPC's pricing branch picks the
 *  correct $/M-token rate. The provider key carries the canonical pricing
 *  tier, but the model id is preserved for postmortem clarity. */
function tierToModelId(t: Tier): string {
  switch (t) {
    case "sonnet":
      return SONNET_MODEL_ID;
    case "haiku":
      return HAIKU_MODEL_ID;
    case "openai":
      return OPENAI_FALLBACK_MODEL;
  }
}

// -----------------------------------------------------------------------------
// Provider invokers — thin adapters that delegate to FIX-14 providers
// -----------------------------------------------------------------------------

interface ProviderCallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

interface ProviderInvokers {
  anthropic: typeof callAnthropic;
  openai: typeof callOpenAI;
}

async function invokeTier(
  tier: Tier,
  params: ChainParams,
  invokers: ProviderInvokers,
): Promise<ProviderCallResult> {
  if (tier === "sonnet") {
    return await withTimeout(
      invokers.anthropic({
        model: SONNET_MODEL_ID,
        systemPrompt: params.systemPrompt,
        messages: params.messages,
        maxTokens: params.maxTokens,
      }),
      PROVIDER_TIMEOUT_MS,
      "anthropic_sonnet",
    );
  }
  if (tier === "haiku") {
    return await withTimeout(
      invokers.anthropic({
        model: HAIKU_MODEL_ID,
        systemPrompt: params.systemPrompt,
        messages: params.messages,
        // Haiku tier inherits maxTokens but caller already clamped if needed.
        maxTokens: params.maxTokens,
      }),
      PROVIDER_TIMEOUT_MS,
      "anthropic_haiku",
    );
  }
  // openai
  return await withTimeout(
    invokers.openai({
      model: OPENAI_FALLBACK_MODEL,
      systemPrompt: params.systemPrompt,
      messages: params.messages,
      maxTokens: params.maxTokens,
    }),
    PROVIDER_TIMEOUT_MS,
    "openai_gpt4o_mini",
  );
}

// -----------------------------------------------------------------------------
// Error → trace token + retry decision
// -----------------------------------------------------------------------------

interface ErrorVerdict {
  /** Short token for fallback_chain (`429`, `credit`, `auth`, `5xx`, `4xx`,
   *  `timeout`, `unknown`). */
  token: string;
  /** Whether the SAME provider should be retried once (5xx only). */
  retrySameTier: boolean;
}

function classifyError(err: unknown): ErrorVerdict {
  // Order matters — check the most-specific subclasses BEFORE the base
  // ProviderError class so the status-bucket fallthrough doesn't fire.
  if (err instanceof Provider429Error) {
    return { token: "429", retrySameTier: false };
  }
  if (err instanceof ProviderCreditExhaustedError) {
    return { token: "credit", retrySameTier: false };
  }
  if (err instanceof ProviderAuthError) {
    return { token: "auth", retrySameTier: false };
  }
  if (err instanceof ProviderTimeoutError) {
    return { token: "timeout", retrySameTier: false };
  }
  if (err instanceof ProviderError) {
    const s = err.status ?? 0;
    if (s >= 500 && s < 600) return { token: "5xx", retrySameTier: true };
    if (s >= 400 && s < 500) {
      // 4xx label uses the actual status for postmortem clarity.
      return { token: String(s), retrySameTier: false };
    }
  }
  return { token: "unknown", retrySameTier: false };
}

// -----------------------------------------------------------------------------
// Test seam — allow tests to inject mock providers without monkey-patching.
// -----------------------------------------------------------------------------

export interface ChainOverrides {
  /** Replace the Anthropic invoker (used by tests). */
  anthropic?: typeof callAnthropic;
  /** Replace the OpenAI invoker (used by tests). */
  openai?: typeof callOpenAI;
  /** Override env-flag reader (used by tests to inject DISABLE_xxx / RAG_ONLY). */
  envFlag?: (name: string) => boolean;
}

// -----------------------------------------------------------------------------
// Main entry point
// -----------------------------------------------------------------------------

export async function callWithFallback(
  signals: RoutingSignals,
  params: ChainParams,
  ragOnlyText: string,
  overrides: ChainOverrides = {},
): Promise<ChainResult> {
  const readFlag = overrides.envFlag ?? envFlag;
  const fallbackChain: string[] = [];

  // Panic switch — bypass everything, return RAG-only synchronously.
  if (readFlag("RAG_ONLY_MODE")) {
    fallbackChain.push("rag_only:forced");
    logChain({
      provider: "rag_only",
      status: "forced",
      latency_ms: 0,
      fallback_chain: fallbackChain,
      detail: "RAG_ONLY_MODE=1",
    });
    return {
      text: ragOnlyText,
      inputTokens: 0,
      outputTokens: 0,
      provider: "rag_only",
      routing_reason: "rag_only_mode_env",
      fallback_chain: fallbackChain,
    };
  }

  // 1. Initial choice from router.
  const initial = selectModel(signals);

  // 2. Build attempt sequence honouring env switches + anon cost protection.
  const sequence = buildAttemptSequence(initial.model, signals, {
    disableHaiku: readFlag("DISABLE_HAIKU_FALLBACK"),
    disableOpenAI: readFlag("DISABLE_OPENAI_FALLBACK"),
  });

  const invokers: ProviderInvokers = {
    anthropic: overrides.anthropic ?? callAnthropic,
    openai: overrides.openai ?? callOpenAI,
  };

  // 3. Walk the chain.
  for (const tier of sequence) {
    const label = tierLabel(tier);

    // Up to 2 attempts on this tier (only 5xx triggers the second).
    for (let attempt = 0; attempt < 2; attempt++) {
      const t0 = Date.now();
      try {
        const result = await invokeTier(tier, params, invokers);
        const latency = Date.now() - t0;
        const trace = attempt === 0 ? `${label}:ok` : `${label}:ok_retry`;
        fallbackChain.push(trace);
        logChain({
          provider: tierToChainProvider(tier),
          status: "ok",
          latency_ms: latency,
          fallback_chain: fallbackChain,
        });

        // FIX-WAVE 19 — record spend BEFORE returning. Without this the
        // OpenAI / Haiku fallback paths were completely unmetered, so the
        // daily soft cap (checkDailyCap) could not throttle them. Awaited
        // (not fire-and-forget) so accounting is reliable across edge-fn
        // suspensions. spend_tracker is failsafe (never throws), so this
        // costs at most one DB round-trip (~30-80 ms) per chain success,
        // which is noise next to the multi-second LLM call we just made.
        await recordSpend(
          result.inputTokens,
          result.outputTokens,
          tierToModelId(tier),
          tierToChainProvider(tier) as SpendProvider,
        );

        return {
          text: result.text,
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
          provider: tierToChainProvider(tier),
          routing_reason: initial.reason,
          fallback_chain: fallbackChain,
        };
      } catch (err) {
        const latency = Date.now() - t0;
        const verdict = classifyError(err);
        const detail = err instanceof Error ? err.message : String(err);
        fallbackChain.push(`${label}:${verdict.token}`);
        logChain({
          provider: tierToChainProvider(tier),
          status: verdict.token,
          latency_ms: latency,
          fallback_chain: fallbackChain,
          detail,
        });

        // Loud log for auth — key likely revoked / wrong.
        if (verdict.token === "auth") {
          console.error(
            `[chain] AUTH FAILURE on ${tierToChainProvider(tier)} — ` +
              `check API key. Skipping tier.`,
            { detail },
          );
        }

        // 5xx → single retry on same tier with short backoff.
        if (verdict.retrySameTier && attempt === 0) {
          await new Promise((r) => setTimeout(r, RETRY_5XX_BACKOFF_MS));
          continue;
        }
        // Otherwise drop to next tier.
        break;
      }
    }
  }

  // 4. Everything failed → RAG-only fallback.
  fallbackChain.push("rag_only:exhausted");
  logChain({
    provider: "rag_only",
    status: "exhausted",
    latency_ms: 0,
    fallback_chain: fallbackChain,
    detail: "all providers failed",
  });
  return {
    text: ragOnlyText,
    inputTokens: 0,
    outputTokens: 0,
    provider: "rag_only",
    routing_reason: initial.reason,
    fallback_chain: fallbackChain,
  };
}
