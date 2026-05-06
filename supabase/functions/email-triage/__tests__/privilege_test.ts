// Deno tests for email-triage/privilege.ts (D4 — Rule 16 / 16.bis classifier).
// -----------------------------------------------------------------------------
// We pin the four trigger conditions (own_counsel allowlist, domain
// match, body marker) and verify that the own_counsel allowlist always
// takes precedence over the otherwise-aggressive domain match.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { classifyPrivilege } from "../privilege.ts";

const PRIVILEGED_DOMAINS = [".law", "asianajotoimisto.fi", "advokaadibüroo"];

Deno.test("classifyPrivilege — opposing counsel triggers privilege flag", () => {
  const r = classifyPrivilege({
    sender_email: "erkki@asianajotoimisto.fi",
    privileged_domains: PRIVILEGED_DOMAINS,
    own_counsel_emails: [],
  });
  assertEquals(r.is_own_counsel, false);
  assertEquals(r.is_likely_privileged, true);
  assert(r.matched_signals.length > 0);
});

Deno.test("classifyPrivilege — own counsel allowlist bypasses domain block", () => {
  const r = classifyPrivilege({
    sender_email: "minna.jokela@asianajotoimisto-jokela.fi",
    privileged_domains: PRIVILEGED_DOMAINS,
    own_counsel_emails: ["minna.jokela@asianajotoimisto-jokela.fi"],
  });
  assertEquals(r.is_own_counsel, true);
  // Own-counsel takes precedence — is_likely_privileged is false because
  // we want the model to PROCESS the body for the Jokela-pattern fix.
  assertEquals(r.is_likely_privileged, false);
  assert(r.matched_signals.includes("own_counsel_allowlist"));
});

Deno.test("classifyPrivilege — body marker triggers privilege flag", () => {
  const r = classifyPrivilege({
    sender_email: "random@example.com",
    body_plaintext: "ATTORNEY-CLIENT PRIVILEGED — confidential.",
    privileged_domains: PRIVILEGED_DOMAINS,
    own_counsel_emails: [],
  });
  assertEquals(r.is_own_counsel, false);
  assertEquals(r.is_likely_privileged, true);
  assert(
    r.matched_signals.some((s) => s.startsWith("privilege_marker:")),
  );
});

Deno.test("classifyPrivilege — non-privileged sender clean-passes", () => {
  const r = classifyPrivilege({
    sender_email: "kirjaamo@valtiokonttori.fi",
    privileged_domains: PRIVILEGED_DOMAINS,
    own_counsel_emails: [],
  });
  assertEquals(r.is_own_counsel, false);
  assertFalse(r.is_likely_privileged);
});

Deno.test("classifyPrivilege — Reply-To override matches own counsel", () => {
  const r = classifyPrivilege({
    sender_email: "noreply@oikeus.fi",
    reply_to: "minna.jokela@oikeus.fi",
    privileged_domains: PRIVILEGED_DOMAINS,
    own_counsel_emails: ["minna.jokela@oikeus.fi"],
  });
  assertEquals(r.is_own_counsel, true);
});
