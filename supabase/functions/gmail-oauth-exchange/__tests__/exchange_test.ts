// gmail-oauth-exchange/__tests__/exchange_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for buildExchangeBody — the URLSearchParams builder
// for the `code` → `{access_token, refresh_token, ...}` exchange against
// https://oauth2.googleapis.com/token.
//
// Run:
//   deno test --allow-env --allow-net --allow-read \
//     supabase/functions/gmail-oauth-exchange/__tests__/exchange_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { buildExchangeBody } from "../exchange.ts";

Deno.test("buildExchangeBody — encodes all five required fields", () => {
  const body = buildExchangeBody({
    code: "4/0AeanS0a.fake-google-code",
    clientId: "1234.apps.googleusercontent.com",
    clientSecret: "GOCSPX-secret",
    redirectUri: "https://advocat.ee/oauth/gmail/return",
  });
  assert(body instanceof URLSearchParams);
  // grant_type is always the literal "authorization_code" — anything else
  // would silently turn this into a refresh-token request (or worse).
  assertEquals(body.get("grant_type"), "authorization_code");
  assertEquals(body.get("code"), "4/0AeanS0a.fake-google-code");
  assertEquals(body.get("client_id"), "1234.apps.googleusercontent.com");
  assertEquals(body.get("client_secret"), "GOCSPX-secret");
  assertEquals(
    body.get("redirect_uri"),
    "https://advocat.ee/oauth/gmail/return",
  );
});

Deno.test("buildExchangeBody — toString produces URL-encoded form body", () => {
  const body = buildExchangeBody({
    code: "code with spaces",
    clientId: "abc.googleusercontent.com",
    clientSecret: "GOCSPX-with-?-and-&-chars",
    redirectUri: "https://advocat.ee/oauth/gmail/return",
  });
  const s = body.toString();
  // Spaces and reserved chars must be percent-encoded so the form body is
  // safe to POST as application/x-www-form-urlencoded.
  assert(!s.includes("code with spaces"), "raw spaces leaked into form body");
  assert(
    s.includes("client_secret=GOCSPX-with-%3F-and-%26-chars"),
    "client_secret special chars not encoded — got: " + s,
  );
  assert(s.includes("grant_type=authorization_code"));
});
