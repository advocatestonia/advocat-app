// Device-link + authCode tests. The QR fixture's authCode was ACCEPTED BY THE
// LIVE SK DEMO CORE (session completed OK), so reproducing it byte-for-byte is
// the strongest available oracle for the HMAC construction.

import {
  buildAuthCodePayload,
  buildDeviceLink,
  buildUnprotectedDeviceLink,
  computeAuthCode,
} from "../lib/devicelink.ts";
import { assert, assertEquals, loadFixture } from "./testutil.ts";

Deno.test("unprotected QR device link: parameter order is normative", () => {
  const link = buildUnprotectedDeviceLink({
    deviceLinkBase: "https://sid.demo.sk.ee/device-link",
    deviceLinkType: "QR",
    elapsedSeconds: 3,
    sessionToken: "tok123",
    sessionType: "auth",
  });
  assertEquals(
    link,
    "https://sid.demo.sk.ee/device-link?deviceLinkType=QR&elapsedSeconds=3&sessionToken=tok123&sessionType=auth&version=1.0&lang=eng"
  );
});

Deno.test(
  "same-device link must NOT contain elapsedSeconds; QR requires it",
  () => {
    const w2a = buildUnprotectedDeviceLink({
      deviceLinkBase: "https://x",
      deviceLinkType: "Web2App",
      sessionToken: "t",
      sessionType: "auth",
    });
    assert(
      !w2a.includes("elapsedSeconds"),
      "Web2App link must not carry elapsedSeconds"
    );
    let threw = false;
    try {
      buildUnprotectedDeviceLink({
        deviceLinkBase: "https://x",
        deviceLinkType: "QR",
        sessionToken: "t",
        sessionType: "auth",
      });
    } catch {
      threw = true;
    }
    assert(threw, "QR without elapsedSeconds must throw");
  }
);

Deno.test(
  "authCode reproduces the value accepted by live SK demo core (QR fixture)",
  async () => {
    const fx = loadFixture("live_qr.json");
    const payload = buildAuthCodePayload({
      schemeName: fx.schemeName, // "smart-id-demo"
      rpChallengeB64: fx.rpChallenge,
      relyingPartyName: fx.request.relyingPartyName, // "DEMO"
      brokeredRpName: "",
      interactionsB64: fx.request.interactions,
      initialCallbackUrl: "", // QR: empty but separator kept
      unprotectedDeviceLink: fx.unprotectedDeviceLink!,
    });
    const authCode = await computeAuthCode(fx.init.sessionSecret!, payload);
    assertEquals(
      authCode,
      fx.authCode,
      "authCode must match the live-accepted value"
    );
    assert(
      !authCode.includes("="),
      "authCode must be Base64URL without padding"
    );
    assert(!/[+/]/.test(authCode), "authCode must use the Base64URL alphabet");
  }
);

Deno.test(
  "buildDeviceLink appends authCode to the unprotected link",
  async () => {
    const fx = loadFixture("live_qr.json");
    // Reconstruct elapsedSeconds from the fixture's unprotected link.
    const elapsed = Number(
      fx.unprotectedDeviceLink!.match(/elapsedSeconds=(\d+)/)![1]
    );
    const { deviceLink, unprotectedDeviceLink, authCode } =
      await buildDeviceLink(
        {
          deviceLinkBase: fx.init.deviceLinkBase!,
          deviceLinkType: "QR",
          elapsedSeconds: elapsed,
          sessionToken: fx.init.sessionToken!,
          sessionType: "auth",
        },
        {
          schemeName: fx.schemeName,
          rpChallengeB64: fx.rpChallenge,
          relyingPartyName: fx.request.relyingPartyName,
          interactionsB64: fx.request.interactions,
          initialCallbackUrl: "",
        },
        fx.init.sessionSecret!
      );
    assertEquals(unprotectedDeviceLink, fx.unprotectedDeviceLink);
    assertEquals(authCode, fx.authCode);
    assertEquals(
      deviceLink,
      `${fx.unprotectedDeviceLink}&authCode=${fx.authCode}`
    );
  }
);
