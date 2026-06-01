// check-vehicle input validators
// -----------------------------------------------------------------------------
// Pure boundary guards for the vehicle-lookup function. Kept in their own module
// so the test can import them without booting index.ts's serve() handler.
//
//   • normalizeCountry — maps a 2-letter code or EN/native country name to a
//     canonical ISO-3166-1 alpha-2 key; unknown input falls back to "EE".
//   • isPlateValid — accepts only 3–12 chars of Latin/Cyrillic letters, digits,
//     hyphen and space. This is the gate before the plate is placed into the LKF
//     POST body (p_reg_no), so it must reject control chars / injection payloads.
// -----------------------------------------------------------------------------

export function normalizeCountry(raw: string | undefined | null): string {
  if (!raw) return "EE";
  const s = raw.trim().toLowerCase();
  if (s.length === 2) return s.toUpperCase();
  const aliases: Record<string, string> = {
    estonia: "EE", eesti: "EE",
    finland: "FI", suomi: "FI",
    latvia: "LV", latvija: "LV",
    lithuania: "LT", lietuva: "LT",
    germany: "DE", deutschland: "DE",
    poland: "PL", polska: "PL",
    sweden: "SE", sverige: "SE",
  };
  return aliases[s] ?? "EE";
}

export function isPlateValid(plate: string): boolean {
  if (typeof plate !== "string") return false;
  if (plate.length < 3 || plate.length > 12) return false;
  // Only a literal ASCII space is allowed as a separator — NOT the \s class,
  // which also matches CR/LF/TAB and would let control chars through (CRLF
  // injection into the LKF POST body).
  return /^[A-Za-zÅÄÖÕÜа-яА-Я0-9\- ]+$/.test(plate);
}
