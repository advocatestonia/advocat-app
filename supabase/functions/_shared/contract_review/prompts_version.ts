// prompts_version.ts — Contract Review prompt versioning.
// -----------------------------------------------------------------------------
// Mirrors `email_agent_prompt.ts::pickPromptVersion`: env-var resolved at call
// time, sanitised against a known-versions allowlist. Unknown values fall back
// to the default so a typo in the deploy env never breaks Anthropic prompt
// cache reuse.
// -----------------------------------------------------------------------------

/** Default version when the env var is unset. Bump only when the assembled
 * prompt changes in a way that warrants invalidating the Anthropic prompt
 * cache. */
export const kContractReviewPromptVersionDefault = "v1.0";

/** Currently known versions. Anything else falls back to default. */
export const kContractReviewPromptKnownVersions: readonly string[] = [
  "v1.0",
];

/** Read `CONTRACT_REVIEW_PROMPT_VERSION` and return a sanitised version
 * string. Pass [envOverride] in tests; in production the env var is the
 * authoritative source so secret rotation flips the version, not code
 * deploys. */
export function pickContractReviewVersion(envOverride?: string): string {
  if (envOverride !== undefined && envOverride !== null) {
    if (envOverride.length === 0) {
      return kContractReviewPromptVersionDefault;
    }
    return kContractReviewPromptKnownVersions.includes(envOverride)
      ? envOverride
      : kContractReviewPromptVersionDefault;
  }
  let raw: string | undefined;
  try {
    raw = Deno.env.get("CONTRACT_REVIEW_PROMPT_VERSION") ?? undefined;
  } catch (_) {
    // Deno.env may be unavailable in restricted runtimes; default is fine.
    raw = undefined;
  }
  if (raw === undefined || raw.length === 0) {
    return kContractReviewPromptVersionDefault;
  }
  return kContractReviewPromptKnownVersions.includes(raw)
    ? raw
    : kContractReviewPromptVersionDefault;
}
