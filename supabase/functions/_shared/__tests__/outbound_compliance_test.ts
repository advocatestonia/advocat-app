// Tests for _shared/outbound_compliance.ts — UPL boundary + disclosure footer
// + recency-windowed recipient allowlist.
//
// These fixtures lock down:
//   1. The Finland / Estonia authority domain suffixes (audit 08 §9.2 + 09
//      §P0-EE-2). Adding or removing a domain from the suffix lists must
//      update both code and these assertions in the same commit.
//   2. The 4 mandatory disclosure-footer points (audit 08 §1.6.2). The
//      strings are loaded by composeDisclosureFooter; we test for the
//      semantic markers, not exact byte-for-byte equality, so the wording
//      can be refined without breaking the fixture, but the meaning is
//      hard-coded.
//   3. F-004 30-day recency window (audit 05).
//   4. Hard-deny patterns (audit 05 F-004 sub-fix #5).
//
// Coordination memory key: swarm/security_audit_2026-05-28/wave1/email_agent

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  ALLOWLIST_RECENCY_DAYS,
  AUTHORITY_RATE_LIMIT_24H,
  classifyRecipient,
  composeDisclosureFooter,
  isRecipientAllowed,
  _domainOf,
  _isDisposable,
} from "../outbound_compliance.ts";

// =============================================================================
// classifyRecipient — Finland authorities
// =============================================================================

Deno.test("classifyRecipient: FI court (käräjäoikeus) is fi_authority", () => {
  const r = classifyRecipient(["jokela.helsinki@oikeus.fi"]);
  assertEquals(r.class, "fi_authority");
  assertEquals(r.friction, 3);
  assertStringIncludes(r.reasons.join("|"), "fi_authority");
});

Deno.test("classifyRecipient: FI police (poliisi.fi) is fi_authority", () => {
  const r = classifyRecipient(["kirjaamo.helsinki@poliisi.fi"]);
  assertEquals(r.class, "fi_authority");
  assertEquals(r.friction, 3);
});

Deno.test("classifyRecipient: FI ombudsman (oikeusasiamies) is fi_authority", () => {
  const r = classifyRecipient(["info@oikeusasiamies.fi"]);
  assertEquals(r.class, "fi_authority");
  assertEquals(r.friction, 3);
});

Deno.test("classifyRecipient: FI chancellor (oikeuskansleri) is fi_authority", () => {
  const r = classifyRecipient(["kirjaamo@oikeuskansleri.fi"]);
  assertEquals(r.class, "fi_authority");
});

Deno.test("classifyRecipient: FI migri (migri.fi) is fi_authority", () => {
  const r = classifyRecipient(["info@migri.fi"]);
  assertEquals(r.class, "fi_authority");
});

Deno.test("classifyRecipient: FI KHO (kho.fi) is fi_authority", () => {
  const r = classifyRecipient(["kirjaamo@kho.fi"]);
  assertEquals(r.class, "fi_authority");
});

Deno.test("classifyRecipient: subdomain *.poliisi.fi inherits fi_authority", () => {
  const r = classifyRecipient(["dept.krp.poliisi.fi@krp.poliisi.fi"]);
  assertEquals(r.class, "fi_authority");
});

// =============================================================================
// classifyRecipient — Estonia authorities
// =============================================================================

Deno.test("classifyRecipient: EE Advokatuur (info@advokatuur.ee) is ee_authority", () => {
  const r = classifyRecipient(["info@advokatuur.ee"]);
  assertEquals(r.class, "ee_authority");
  assertEquals(r.friction, 3);
});

Deno.test("classifyRecipient: EE kohus (kohus.ee) is ee_authority", () => {
  const r = classifyRecipient(["info@kohus.ee"]);
  assertEquals(r.class, "ee_authority");
});

Deno.test("classifyRecipient: EE PPA (politsei.ee) is ee_authority", () => {
  const r = classifyRecipient(["info@politsei.ee"]);
  assertEquals(r.class, "ee_authority");
});

Deno.test("classifyRecipient: EE AKI (aki.ee) is ee_authority", () => {
  const r = classifyRecipient(["info@aki.ee"]);
  assertEquals(r.class, "ee_authority");
});

Deno.test("classifyRecipient: EE Õiguskantsler is ee_authority", () => {
  const r = classifyRecipient(["info@oiguskantsler.ee"]);
  assertEquals(r.class, "ee_authority");
});

// =============================================================================
// classifyRecipient — standard / asianajaja
// =============================================================================

Deno.test("classifyRecipient: random gmail address is standard", () => {
  const r = classifyRecipient(["random@gmail.com"]);
  assertEquals(r.class, "standard");
  assertEquals(r.friction, 0);
});

Deno.test("classifyRecipient: yandex / outlook / proton — all standard", () => {
  assertEquals(classifyRecipient(["a@yandex.ru"]).class, "standard");
  assertEquals(classifyRecipient(["a@outlook.com"]).class, "standard");
  assertEquals(classifyRecipient(["a@proton.me"]).class, "standard");
});

Deno.test("classifyRecipient: nominated counsel domain → asianajaja", () => {
  const r = classifyRecipient(
    ["counsel@hannes-snellman.com"],
    new Set(["hannes-snellman.com"]),
  );
  assertEquals(r.class, "asianajaja");
  assertEquals(r.friction, 1);
});

Deno.test("classifyRecipient: nominated EE law firm → asianajaja", () => {
  const r = classifyRecipient(
    ["partner@sorainen.com"],
    new Set(["sorainen.com"]),
  );
  assertEquals(r.class, "asianajaja");
});

// =============================================================================
// classifyRecipient — hard-deny
// =============================================================================

Deno.test("classifyRecipient: .onion is denied", () => {
  const r = classifyRecipient(["dropbox@abc123def456.onion"]);
  assertEquals(r.class, "denied");
  assertEquals(r.friction, 3);
});

Deno.test("classifyRecipient: disposable mailinator is denied", () => {
  const r = classifyRecipient(["temp@mailinator.com"]);
  assertEquals(r.class, "denied");
});

Deno.test("classifyRecipient: guerrillamail is denied", () => {
  const r = classifyRecipient(["x@guerrillamail.com"]);
  assertEquals(r.class, "denied");
});

Deno.test("classifyRecipient: empty recipient list → denied", () => {
  const r = classifyRecipient([]);
  assertEquals(r.class, "denied");
});

Deno.test("classifyRecipient: malformed (no @) → denied", () => {
  const r = classifyRecipient(["not-an-email"]);
  assertEquals(r.class, "denied");
});

// =============================================================================
// classifyRecipient — multi-recipient escalates to worst class
// =============================================================================

Deno.test(
  "classifyRecipient: standard + fi_authority → fi_authority (worst wins)",
  () => {
    const r = classifyRecipient([
      "user@gmail.com",
      "jokela.helsinki@oikeus.fi",
    ]);
    assertEquals(r.class, "fi_authority");
    assertEquals(r.friction, 3);
  },
);

Deno.test(
  "classifyRecipient: standard + denied → denied (denied is highest)",
  () => {
    const r = classifyRecipient([
      "user@gmail.com",
      "exfil@mailinator.com",
    ]);
    assertEquals(r.class, "denied");
  },
);

Deno.test(
  "classifyRecipient: ee_authority + fi_authority → fi_authority (deterministic)",
  () => {
    const r = classifyRecipient([
      "info@kohus.ee",
      "jokela@oikeus.fi",
    ]);
    assertEquals(r.class, "fi_authority");
    assertEquals(r.friction, 3);
  },
);

// =============================================================================
// composeDisclosureFooter — 4 mandatory points per audit 08 §1.6.2
// =============================================================================

Deno.test(
  "composeDisclosureFooter: FI authority footer covers all 4 mandatory points",
  () => {
    const f = composeDisclosureFooter(
      "fi",
      "fi_authority",
      "Dmitri Sulga",
    );
    // (1) prepared with Advocat AI
    assertStringIncludes(f, "Advocat");
    // (2) not a law firm / not under Asianajajaliitto supervision
    assertStringIncludes(f, "asianajotoimisto");
    assertStringIncludes(f, "Asianajajaliiton");
    // (3) sent from user's own mailbox (user is the legal sender)
    assertStringIncludes(f, "omasta puolestaan");
    // (4) no attorney-client privilege
    assertStringIncludes(f, "asianajosalaisuuden");
    // user's full name appears
    assertStringIncludes(f, "Dmitri Sulga");
    // contact / provenance
    assertStringIncludes(f, "advocat.ee");
    assertStringIncludes(f, "Vorantis");
  },
);

Deno.test(
  "composeDisclosureFooter: EE authority footer covers all 4 mandatory points",
  () => {
    const f = composeDisclosureFooter(
      "et",
      "ee_authority",
      "Sofia Sulga",
    );
    assertStringIncludes(f, "Advocat");
    assertStringIncludes(f, "advokaadibüroo"); // not a law firm
    assertStringIncludes(f, "Advokatuuriseaduse"); // EE bar law cite
    assertStringIncludes(f, "iseenda nimel"); // user is the legal sender
    assertStringIncludes(f, "advokaadisaladusega"); // no privilege
    assertStringIncludes(f, "Sofia Sulga");
    assertStringIncludes(f, "advocat.ee");
  },
);

Deno.test(
  "composeDisclosureFooter: EN authority footer covers all 4 mandatory points",
  () => {
    const f = composeDisclosureFooter(
      "en",
      "fi_authority",
      "Test User",
    );
    assertStringIncludes(f, "Advocat");
    assertStringIncludes(f, "not a law firm");
    assertStringIncludes(f, "own mailbox");
    assertStringIncludes(f, "attorney-client privilege");
    assertStringIncludes(f, "Test User");
  },
);

Deno.test(
  "composeDisclosureFooter: RU authority footer covers all 4 mandatory points",
  () => {
    const f = composeDisclosureFooter(
      "ru",
      "fi_authority",
      "Дмитрий Шульга",
    );
    assertStringIncludes(f, "Advocat");
    assertStringIncludes(f, "адвокатским бюро"); // not a law firm
    assertStringIncludes(f, "почтового ящика"); // own mailbox
    assertStringIncludes(f, "адвокатской тайной"); // no privilege
    assertStringIncludes(f, "Дмитрий Шульга");
  },
);

Deno.test(
  "composeDisclosureFooter: standard class uses short footer (not full disclosure)",
  () => {
    const fShort = composeDisclosureFooter("fi", "standard", "X");
    const fAuth = composeDisclosureFooter("fi", "fi_authority", "X");
    assert(
      fShort.length < fAuth.length,
      "short footer must be shorter than authority footer",
    );
    assertStringIncludes(fShort, "Advocat");
    assertStringIncludes(fShort, "advocat.ee");
  },
);

Deno.test(
  "composeDisclosureFooter: starts with newline separator (--- delimiter)",
  () => {
    const f = composeDisclosureFooter("fi", "fi_authority", "X");
    assert(f.startsWith("\n\n---\n"), "must start with body separator");
  },
);

// =============================================================================
// isRecipientAllowed — 30-day recency + hard-deny
// =============================================================================

Deno.test("isRecipientAllowed: in-window inbound sender is allowed", () => {
  const r = isRecipientAllowed({
    recipient: "lawyer@example.com",
    user_id: "u1",
    inboundHistory: [
      { from: "lawyer@example.com", sent_at: new Date() },
    ],
  });
  assertEquals(r.ok, true);
});

Deno.test(
  "isRecipientAllowed: stale inbound (older than recency window) is denied",
  () => {
    const stale = new Date(
      Date.now() - (ALLOWLIST_RECENCY_DAYS + 1) * 24 * 60 * 60 * 1_000,
    );
    const r = isRecipientAllowed({
      recipient: "lawyer@example.com",
      user_id: "u1",
      inboundHistory: [
        { from: "lawyer@example.com", sent_at: stale },
      ],
    });
    assertEquals(r.ok, false);
    assertEquals(r.denied_by, "recency");
  },
);

Deno.test("isRecipientAllowed: empty history → denied with no_history", () => {
  const r = isRecipientAllowed({
    recipient: "lawyer@example.com",
    user_id: "u1",
    inboundHistory: [],
  });
  assertEquals(r.ok, false);
  assertEquals(r.denied_by, "no_history");
});

Deno.test("isRecipientAllowed: hard-deny .onion regardless of history", () => {
  const r = isRecipientAllowed({
    recipient: "exfil@abc123.onion",
    user_id: "u1",
    inboundHistory: [
      { from: "exfil@abc123.onion", sent_at: new Date() },
    ],
  });
  assertEquals(r.ok, false);
  assertEquals(r.denied_by, "tld_hardlist");
});

Deno.test("isRecipientAllowed: hard-deny disposable regardless of history", () => {
  const r = isRecipientAllowed({
    recipient: "temp@mailinator.com",
    user_id: "u1",
    inboundHistory: [
      { from: "temp@mailinator.com", sent_at: new Date() },
    ],
  });
  assertEquals(r.ok, false);
  assertEquals(r.denied_by, "tld_hardlist");
});

Deno.test("isRecipientAllowed: invalid recipient (no @) → denied", () => {
  const r = isRecipientAllowed({
    recipient: "not-an-email",
    user_id: "u1",
    inboundHistory: [],
  });
  assertEquals(r.ok, false);
});

Deno.test(
  "isRecipientAllowed: case-insensitive match on recipient and history",
  () => {
    const r = isRecipientAllowed({
      recipient: "Jokela.Helsinki@OIKEUS.fi",
      user_id: "u1",
      inboundHistory: [
        { from: "jokela.helsinki@oikeus.fi", sent_at: new Date() },
      ],
    });
    assertEquals(r.ok, true);
  },
);

// =============================================================================
// Constants — exposed so callers / downstream gates can rely on them
// =============================================================================

Deno.test("AUTHORITY_RATE_LIMIT_24H = 3 (audit 08 §9.2)", () => {
  assertEquals(AUTHORITY_RATE_LIMIT_24H, 3);
});

Deno.test("ALLOWLIST_RECENCY_DAYS = 30 (audit 05 F-004)", () => {
  assertEquals(ALLOWLIST_RECENCY_DAYS, 30);
});

// =============================================================================
// Helpers exported for tests
// =============================================================================

Deno.test("_domainOf: lowercases and strips local part", () => {
  assertEquals(_domainOf("X@Example.COM"), "example.com");
  assertEquals(_domainOf("  user@oikeus.fi  "), "oikeus.fi");
  assertEquals(_domainOf("no-at-sign"), "no-at-sign");
});

Deno.test("_isDisposable: mailinator is on the list", () => {
  assertEquals(_isDisposable("mailinator.com"), true);
  assertEquals(_isDisposable("gmail.com"), false);
});
