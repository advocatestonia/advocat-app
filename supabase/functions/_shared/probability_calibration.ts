// probability_calibration.ts — Pure calibration guard for probability signals.
// -----------------------------------------------------------------------------
// Anchors from CALIBRATION_BLOCK — these are the base rates the Реалист
// should use. If any stated probability exceeds the anchor by >25 pp,
// we flag it so the trace row records the overclaim.
// -----------------------------------------------------------------------------

export interface CalibrationAnchor {
  label: string;
  highEnd: number; // upper bound of the base-rate range in percent
}

export const CALIBRATION_ANCHORS: CalibrationAnchor[] = [
  { label: "valituslupa", highEnd: 20 },
  { label: "menetetyn määräajan", highEnd: 15 },
  { label: "restoration", highEnd: 15 },
  { label: "echr", highEnd: 8 },
  { label: "deportation appeal", highEnd: 35 },
  { label: "compensation", highEnd: 70 },
  { label: "administrative correction", highEnd: 40 },
];

/**
 * Parse the first NN–MM% range from a string.
 * Returns the HIGH end as a number, or null if no range found.
 */
export function parseHighEnd(text: string): number | null {
  const m = text.match(/(\d{1,3})\s*[–—-]\s*(\d{1,3})\s*%/);
  if (!m) return null;
  return parseInt(m[2], 10);
}

/**
 * Check if a probability signal is overclaiming relative to base rates.
 * Returns a warning string if overclaim detected, null otherwise.
 */
export function checkCalibration(
  probabilitySignal: string,
  context: string, // the legal question/context to match anchors
): string | null {
  const highEnd = parseHighEnd(probabilitySignal);
  if (highEnd === null) return null;

  const contextLower = context.toLowerCase();
  for (const anchor of CALIBRATION_ANCHORS) {
    if (contextLower.includes(anchor.label.toLowerCase())) {
      if (highEnd > anchor.highEnd + 25) {
        return `calibration-warning: stated high end ${highEnd}% exceeds base rate anchor for "${anchor.label}" (${anchor.highEnd}%) by ${highEnd - anchor.highEnd} pp`;
      }
    }
  }
  return null;
}
