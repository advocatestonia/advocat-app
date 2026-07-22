// Pure-logic tests: verification code + ACSP_V2 message construction.
// Golden vectors: (a) SK docs example from rp-api/signature_protocols.html,
// (b) values captured from a LIVE SK demo session on 2026-07-17.

import { buildAcspV2Message, computeVerificationCode } from "../lib/acsp.ts";
import { b64Decode } from "../lib/b64.ts";
import { assert, assertEquals, loadFixture } from "./testutil.ts";

Deno.test(
  "VC formula matches live demo session (SHA-256 last-2-bytes mod 10000)",
  async () => {
    const fx = loadFixture("live_notification.json");
    const vc = await computeVerificationCode(b64Decode(fx.rpChallenge));
    assertEquals(
      vc,
      fx.expectedVC,
      "VC must match the value recorded during the live session"
    );
  }
);

Deno.test("VC is always 4 digits (zero-padded)", async () => {
  // fixed challenge whose VC is deterministic
  const vc = await computeVerificationCode(new Uint8Array(64));
  assert(/^[0-9]{4}$/.test(vc), `VC '${vc}' is not 4 digits`);
});

Deno.test(
  "ACSP_V2 message matches SK documentation example (field order + separators)",
  async () => {
    // Inputs copied verbatim from the SK docs example (signature_protocols.html).
    const msg = await buildAcspV2Message({
      schemeName: "smart-id",
      serverRandom: "MTlop6EXCrQ6FOErcKjxUhbV",
      rpChallengeB64:
        "GYS+yoah6emAcVDNIajwSs6UB/M95XrDxMzXBUkwQJ9YFDipXXzGpPc7raWcuc2+TEoRc7WvIZ/7dU/iRXenYg==",
      userChallenge: "GnsWXXEjTCKR89fj9uo5u5ReBZ9JR7_pezLAI5jMS00",
      relyingPartyName: "DEMO",
      brokeredRpName: "Example RP",
      interactionsB64:
        "W3sidHlwZSI6ImNvbmZpcm1hdGlvbk1lc3NhZ2UiLCJkaXNwbGF5VGV4dDIwMCI6IkxvbmdlciBkZXNjcmlwdGlvbiBvZiB0aGUgdHJhbnNhY3Rpb24gY29udGV4dCJ9LHsidHlwZSI6ImRpc3BsYXlUZXh0QW5kUElOIiwiZGlzcGxheVRleHQ2MCI6IlNob3J0IGRlc2NyaXB0aW9uIG9mIHRoZSB0cmFuc2FjdGlvbiBjb250ZXh0In1d",
      interactionTypeUsed: "confirmationMessage",
      initialCallbackUrl:
        "https://rp.example.com/callback-url?value=RrKjjT4aggzu27YBddX1bQ",
      flowType: "Web2App",
    });

    const parts = msg.split("|");
    assertEquals(
      parts.length,
      11,
      "ACSP_V2 payload must have exactly 11 fields"
    );
    assertEquals(parts[0], "smart-id");
    assertEquals(parts[1], "ACSP_V2");
    assertEquals(
      parts[5],
      "REVNTw==",
      "relyingPartyName must be Base64('DEMO')"
    );
    assertEquals(
      parts[6],
      "RXhhbXBsZSBSUA==",
      "brokeredRpName must be Base64('Example RP')"
    );
    // SHA-256 of the interactions Base64 STRING (not of the decoded JSON):
    assertEquals(parts[7], "RW2HOCLDvRFNWmAOmpWE+3rt7a8q4JGQD3n75d6xJHM=");

    // Independent golden digest (computed with python hashlib from the docs inputs):
    const digest = new Uint8Array(
      await crypto.subtle.digest("SHA-512", new TextEncoder().encode(msg))
    );
    let bin = "";
    for (const byte of digest) bin += String.fromCharCode(byte);
    assertEquals(
      btoa(bin),
      "pKOjbNl/5Fy8NfrFqsj6pSn8W8O+Ik8rM33QSsbyD3J9qDJvEm90SboUciuY4wHGWa0Pnq8BgT3NJKmJiUDfKg=="
    );
  }
);

Deno.test(
  "ACSP_V2 message: empty brokeredRpName / callback keep their separators",
  async () => {
    const msg = await buildAcspV2Message({
      schemeName: "smart-id-demo",
      serverRandom: "AAAA",
      rpChallengeB64: "BBBB",
      userChallenge: "CCCC",
      relyingPartyName: "DEMO",
      interactionsB64: "W10=",
      interactionTypeUsed: "displayTextAndPIN",
      flowType: "QR",
    });
    const parts = msg.split("|");
    assertEquals(parts.length, 11);
    assertEquals(
      parts[6],
      "",
      "empty brokeredRpName must stay empty, not be dropped"
    );
    assertEquals(
      parts[9],
      "",
      "empty initialCallbackUrl must stay empty, not be dropped"
    );
    assertEquals(parts[10], "QR");
  }
);
