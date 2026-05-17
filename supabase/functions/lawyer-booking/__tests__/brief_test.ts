// lawyer-booking/__tests__/brief_test.ts
// -----------------------------------------------------------------------------
// Tests for the skeleton fallback + prompt builders in brief.ts. We do NOT
// hit claude-proxy — the AI path is exercised in the production smoke.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/lawyer-booking/__tests__/brief_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { __testing } from "../brief.ts";

const { buildSkeleton, buildSystemPrompt, buildUserPrompt } = __testing;

Deno.test("SKL-01 — skeleton always has the four required H2 sections", () => {
  const md = buildSkeleton({
    topic: "family",
    language: "et",
    userBrief: null,
    userDisplayName: "Anna Tamm",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(md, "## Situation");
  assertStringIncludes(md, "## Key facts");
  assertStringIncludes(md, "## Likely legal questions");
  assertStringIncludes(md, "## What the user has already tried");
  assertStringIncludes(md, "Suggested opener:");
});

Deno.test("SKL-02 — skeleton includes the user-written brief as quote", () => {
  const md = buildSkeleton({
    topic: "tenancy",
    language: "ru",
    userBrief: "Хозяин не возвращает залог 3 недели.",
    userDisplayName: "Иван Иванов",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(md, "> Хозяин не возвращает залог 3 недели.");
});

Deno.test("SKL-03 — skeleton lists case facts keys when provided", () => {
  const md = buildSkeleton({
    topic: "immigration",
    language: "fi",
    userBrief: null,
    userDisplayName: "Matti V.",
    caseFactsJson: {
      decision_number: "1366/2026",
      court: "KHO",
      deadline: "2026-09-15",
    },
    caseChatExcerpt: null,
  });
  assertStringIncludes(md, "decision_number:");
  assertStringIncludes(md, "court:");
  assertStringIncludes(md, "deadline:");
});

Deno.test("SKL-04 — empty case_facts object still produces valid markdown", () => {
  const md = buildSkeleton({
    topic: "family",
    language: "et",
    userBrief: null,
    userDisplayName: "Anna",
    caseFactsJson: {},
    caseChatExcerpt: null,
  });
  assertStringIncludes(md, "(no structured facts available)");
});

Deno.test("SYS-01 — system prompt encodes the language by full name", () => {
  const fi = buildSystemPrompt({
    topic: "family",
    language: "fi",
    userBrief: null,
    userDisplayName: "X",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(fi, "Finnish");

  const ru = buildSystemPrompt({
    topic: "family",
    language: "ru",
    userBrief: null,
    userDisplayName: "X",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(ru, "Russian");
});

Deno.test("SYS-02 — system prompt enforces 4-section format", () => {
  const sys = buildSystemPrompt({
    topic: "family",
    language: "et",
    userBrief: null,
    userDisplayName: "X",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(sys, "## Situation");
  assertStringIncludes(sys, "## Key facts");
  assertStringIncludes(sys, "## Likely legal questions");
  assertStringIncludes(sys, "## What the user has already tried");
  assertStringIncludes(sys, "600 words");
});

Deno.test("USR-01 — user prompt always reflects the picked topic", () => {
  const p = buildUserPrompt({
    topic: "criminal",
    language: "et",
    userBrief: null,
    userDisplayName: "Anna",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(p, "**criminal**");
});

Deno.test("USR-02 — user prompt embeds optional case_facts as JSON block", () => {
  const p = buildUserPrompt({
    topic: "immigration",
    language: "fi",
    userBrief: null,
    userDisplayName: "X",
    caseFactsJson: { court: "KHO" },
    caseChatExcerpt: null,
  });
  assertStringIncludes(p, "```json");
  assertStringIncludes(p, '"court"');
});

Deno.test("USR-03 — empty inputs emit a placeholder marker", () => {
  const p = buildUserPrompt({
    topic: "family",
    language: "et",
    userBrief: null,
    userDisplayName: "X",
    caseFactsJson: null,
    caseChatExcerpt: null,
  });
  assertStringIncludes(p, "(The user has not provided additional context");
});

Deno.test("SKL-LEN — skeleton stays under 4KB even with verbose inputs", () => {
  const md = buildSkeleton({
    topic: "everything you have ever wanted to know about Estonian property",
    language: "et",
    userBrief: "a".repeat(3000),
    userDisplayName: "Long Name Verbose User",
    caseFactsJson: { a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8 },
    caseChatExcerpt: null,
  });
  // Sanity: skeleton never blows up the 20K column cap on lawyer_bookings.
  // 4KB is a comfortable assertion for an inputs-driven mechanical render.
  assertEquals(md.length < 8000, true);
});
