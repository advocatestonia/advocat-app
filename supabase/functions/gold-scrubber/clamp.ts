// gold-scrubber batch-size clamp
// -----------------------------------------------------------------------------
// Parses the ?batch= query param into a bounded integer. This caps how many
// rows a single (cron-triggered) run pulls + scrubs, so a stray/hostile value
// can't make the function fetch an unbounded slice of the gold corpus queue or
// run an enormous number of billed Haiku scrub calls. Non-numeric / out-of-range
// input falls back to the default or the nearest bound. Own module so the test
// imports it without booting serve().
// -----------------------------------------------------------------------------

export function clampInt(
  raw: string | null,
  min: number,
  max: number,
  fallback: number,
): number {
  if (!raw) return fallback;
  const n = parseInt(raw, 10);
  if (!Number.isFinite(n)) return fallback;
  if (n < min) return min;
  if (n > max) return max;
  return n;
}
