// End-to-end OFFLINE verification against fixtures captured from LIVE SK demo
// sessions (2026-07-17): ACSP_V2 signature, cert chain vs pinned demo CA,
// identity extraction, and tamper-detection negatives.

import { b64Decode } from "../lib/b64.ts";
import { parseCertificate, parsePem } from "../lib/x509.ts";
import { SK_DEMO_CA_PEMS } from "../lib/sk_demo_ca.ts";
import {
  SessionStatus,
  validateCertificate,
  verifyAuthenticationSession,
} from "../lib/verify.ts";
import {
  assert,
  assertEquals,
  loadFixture,
  NotificationFixture,
} from "./testutil.ts";

// Certificates in the fixtures are valid 2025→2028/2029; pin the clock so the
// validity-window check stays deterministic for years.
const FIXTURE_NOW = new Date("2026-07-17T12:00:00Z");

function verifyFixture(fx: NotificationFixture) {
  return verifyAuthenticationSession({
    session: fx.session as SessionStatus,
    schemeName: fx.schemeName,
    rpChallengeB64: fx.rpChallenge,
    relyingPartyName: fx.request.relyingPartyName,
    interactionsB64: fx.request.interactions,
    trustedCaPems: SK_DEMO_CA_PEMS,
    initialCallbackUrl: "",
    now: FIXTURE_NOW,
  });
}

Deno.test(
  "NOTIFICATION flow: full verification of live session passes",
  async () => {
    const fx = loadFixture("live_notification.json");
    const result = await verifyFixture(fx);
    assert(
      result.signatureValid,
      "ACSP_V2 signature must verify (RSASSA-PSS SHA-512)"
    );
    assert(result.certChainValid, "cert must chain to pinned TEST EID-Q 2024E");
    assert(result.certInValidityWindow, "cert must be within validity window");
    assert(result.ok);
    assertEquals(result.identity?.etsiIdentifier, "PNOEE-40504040001");
    assertEquals(result.identity?.personalCode, "40504040001");
    assertEquals(result.identity?.country, "EE");
    assertEquals(result.identity?.givenName, "OK");
    assertEquals(result.identity?.surname, "TEST");
    assertEquals(result.identity?.documentNumber, "PNOEE-40504040001-DEM2-Q");
    assertEquals(result.certificateLevel, "QUALIFIED");
  }
);

Deno.test(
  "DEVICE-LINK QR flow: full verification of live session passes",
  async () => {
    const fx = loadFixture("live_qr.json");
    const result = await verifyFixture(fx);
    assert(result.ok, `verification failed: ${JSON.stringify(result)}`);
    assertEquals(result.identity?.etsiIdentifier, "PNOEE-40404040009");
    assertEquals(fx.session.signature?.flowType, "QR");
  }
);

Deno.test(
  "tampered rpChallenge is rejected (replay/substitution defence)",
  async () => {
    const fx = loadFixture("live_notification.json");
    const evil = {
      ...fx,
      rpChallenge: fx.rpChallenge.replace(/^..../, "AAAA"),
    };
    const result = await verifyFixture(evil as NotificationFixture);
    assert(
      !result.signatureValid,
      "signature must NOT verify with a different rpChallenge"
    );
    assert(!result.ok);
    assertEquals(
      result.identity,
      undefined,
      "no identity may be returned on failed verification"
    );
  }
);

Deno.test("wrong schemeName ('smart-id' vs demo) is rejected", async () => {
  const fx = loadFixture("live_notification.json");
  const evil = { ...fx, schemeName: "smart-id" };
  const result = await verifyFixture(evil as NotificationFixture);
  assert(
    !result.signatureValid,
    "LIVE schemeName must not verify against a DEMO signature"
  );
});

Deno.test("session with endResult!=OK yields no identity", async () => {
  const fx = loadFixture("live_notification.json");
  const refused = {
    ...fx,
    session: { state: "COMPLETE", result: { endResult: "USER_REFUSED" } },
  };
  const result = await verifyFixture(refused as unknown as NotificationFixture);
  assert(!result.ok);
  assertEquals(result.identity, undefined);
});

Deno.test(
  "x509 parser extracts subject / issuer / validity from live cert",
  () => {
    const fx = loadFixture("live_notification.json");
    const cert = parseCertificate(b64Decode(fx.session.cert!.value));
    assertEquals(cert.subject["serialNumber"], "PNOEE-40504040001");
    assertEquals(cert.subject["givenName"], "OK");
    assertEquals(cert.subject["surname"], "TEST");
    assertEquals(cert.subject["C"], "EE");
    assertEquals(cert.issuer["CN"], "TEST of SK ID Solutions EID-Q 2024E");
    assert(cert.notBefore < cert.notAfter);
    assertEquals(cert.signatureAlgorithmOid, "1.2.840.10045.4.3.3"); // ecdsa-with-SHA384
  }
);

Deno.test(
  "cert chain fails against a non-issuer CA (pin actually pins)",
  async () => {
    const fx = loadFixture("live_notification.json");
    // Use the END-USER cert itself as the "trusted CA" — subject DN differs from
    // the user cert's issuer DN, so the pin must not match.
    const certDer = b64Decode(fx.session.cert!.value);
    const selfPem = `-----BEGIN CERTIFICATE-----\n${
      fx.session.cert!.value
    }\n-----END CERTIFICATE-----`;
    const { chainValid } = await validateCertificate(
      certDer,
      [selfPem],
      FIXTURE_NOW
    );
    assert(!chainValid, "user cert must not chain to itself");
  }
);

Deno.test(
  "expired-clock check: cert outside validity window is flagged",
  async () => {
    const fx = loadFixture("live_notification.json");
    const { inValidityWindow } = await validateCertificate(
      b64Decode(fx.session.cert!.value),
      SK_DEMO_CA_PEMS,
      new Date("2035-01-01T00:00:00Z")
    );
    assert(!inValidityWindow);
  }
);

Deno.test("pinned demo CA parses and is the expected issuing CA", () => {
  const ca = parseCertificate(parsePem(SK_DEMO_CA_PEMS[0]));
  assertEquals(ca.subject["CN"], "TEST of SK ID Solutions EID-Q 2024E");
  assertEquals(ca.issuer["CN"], "TEST of SK ID Solutions ROOT G1E");
});
