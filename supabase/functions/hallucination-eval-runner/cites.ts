// hallucination-eval-runner/cites.ts — env-free citation-analysis core.
// -----------------------------------------------------------------------------
// The false-cite rate (the headline eval metric) is computed entirely from
// these deterministic helpers. FIX-WAVE 12 showed how a silent break upstream
// invalidated the whole 2026-05-19 number — so the citation math itself is
// worth regression-locking. Extracted out of index.ts (which has serve() +
// top-level Deno.env reads) so the suite can import them with --allow-read only.
// -----------------------------------------------------------------------------

export interface Cite {
  raw: string;
  section: string;
  context: string;
}

export interface LookupLike {
  input: { specific_statute?: string };
  returned_chunks: Array<{ section_label: string | null }>;
}

/** Constant-time string compare — avoids a timing oracle on the corpus secret. */
export function timingSafeEqualStr(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

const CITE_PATTERNS: Array<{ re: RegExp; group: number }> = [
  { re: /§\s*([A-ZÄÖÕÜŠŽ]{2,8}\s+\d+:\d+)/g, group: 1 },
  { re: /§\s*(\d+(?::\d+)?)/g, group: 1 },
  { re: /\b(?:Article|art\.?)\s+(\d+(?:\(\d+\))?)/gi, group: 1 },
];

export function extractCites(text: string): Cite[] {
  const out: Cite[] = [];
  const seen = new Set<string>();
  for (const { re, group } of CITE_PATTERNS) {
    re.lastIndex = 0;
    let m: RegExpExecArray | null;
    while ((m = re.exec(text)) !== null) {
      const raw = m[0];
      const section = m[group].replace(/\s+/g, " ").trim();
      const key = section.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      const start = Math.max(0, m.index - 30);
      const end = Math.min(text.length, m.index + raw.length + 30);
      out.push({ raw, section, context: text.slice(start, end) });
    }
  }
  return out;
}

export function sectionFromChunk(label: string | null): string {
  if (!label) return "";
  const stripped = label.replace(/§/g, "").trim();
  const m = stripped.match(/(\d+:\d+|\d+(?:¹|²|³)?)\s*$/);
  if (m) return m[1];
  return stripped;
}

export function citationCovered(c: Cite, lookups: LookupLike[]): boolean {
  const target = c.section.toLowerCase().replace(/\s+/g, "");
  const targetNum = target.match(/(\d+(?::\d+)?)/)?.[1] ?? target;
  for (const lk of lookups) {
    const ss = (lk.input.specific_statute ?? "").toLowerCase();
    if (ss && (ss.includes(target) || ss.includes(targetNum))) return true;
    for (const ch of lk.returned_chunks) {
      const lab = sectionFromChunk(ch.section_label).toLowerCase();
      if (!lab) continue;
      if (lab === target || lab === targetNum) return true;
      if (lab.endsWith(":" + targetNum)) return true;
      if (target.endsWith(":" + lab)) return true;
    }
  }
  return false;
}
