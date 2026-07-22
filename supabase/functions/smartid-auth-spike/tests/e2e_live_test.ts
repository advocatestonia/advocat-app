// OPT-IN live E2E against the real SK demo environment (network required).
// Skipped by default so `deno task test` stays offline/deterministic.
// Run with:
//   SMARTID_SPIKE_LIVE=1 deno test --allow-read --allow-net --allow-env tests/e2e_live_test.ts

import { DEMO_RP_NAME, DEMO_SCHEME_NAME, TEST_ACCOUNTS } from "../config.ts";
import { b64Encode, utf8 } from "../lib/b64.ts";
import { computeVerificationCode, generateRpChallenge } from "../lib/acsp.ts";
import { buildDeviceLink } from "../lib/devicelink.ts";
import {
  getSessionStatus,
  mockScanDeviceLink,
  startAnonymousDeviceLinkAuth,
  startNotificationAuth,
} from "../lib/sk_client.ts";
import { verifyAuthenticationSession } from "../lib/verify.ts";
import { SK_DEMO_CA_PEMS } from "../lib/sk_demo_ca.ts";
import { assert, assertEquals } from "./testutil.ts";

const LIVE = (() => {
  try {
    return Deno.env.get("SMARTID_SPIKE_LIVE") === "1";
  } catch {
    return false; // no --allow-env → offline run, skip live tests
  }
})();

function interactions(text: string): string {
  return b64Encode(
    utf8(JSON.stringify([{ type: "displayTextAndPIN", displayText60: text }]))
  );
}

async function pollUntilComplete(sessionId: string, tries = 12) {
  for (let i = 0; i < tries; i++) {
    const s = await getSessionStatus(sessionId, 10_000);
    if (s.state === "COMPLETE") return s;
  }
  throw new Error("session did not complete in time");
}

Deno.test({
  name: "LIVE notification flow: auto-OK account → verified identity",
  ignore: !LIVE,
  fn: async () => {
    const { bytes, base64: rpChallengeB64 } = generateRpChallenge();
    const interactionsB64 = interactions("Advocat spike e2e");
    const vc = await computeVerificationCode(bytes);
    assert(/^\d{4}$/.test(vc));

    const init = await startNotificationAuth(TEST_ACCOUNTS.notificationOkEtsi, {
      rpChallengeB64,
      interactionsB64,
    });
    const session = await pollUntilComplete(init.sessionID);
    assertEquals(session.result?.endResult, "OK");

    const result = await verifyAuthenticationSession({
      session,
      schemeName: DEMO_SCHEME_NAME,
      rpChallengeB64,
      relyingPartyName: DEMO_RP_NAME,
      interactionsB64,
      trustedCaPems: SK_DEMO_CA_PEMS,
      initialCallbackUrl: "",
    });
    assert(result.ok, `live verification failed: ${JSON.stringify(result)}`);
    assertEquals(result.identity?.etsiIdentifier, "PNOEE-40504040001");
  },
});

Deno.test({
  name: "LIVE device-link QR flow via mock service → verified identity",
  ignore: !LIVE,
  fn: async () => {
    const { base64: rpChallengeB64 } = generateRpChallenge();
    const interactionsB64 = interactions("Advocat spike QR e2e");

    const init = await startAnonymousDeviceLinkAuth({
      rpChallengeB64,
      interactionsB64,
    });
    const createdAt = Date.now();

    // elapsedSeconds must reflect real elapsed time — links "from the future"
    // are silently ignored by the demo core (observed: session → TIMEOUT).
    // The mock's timing tolerance is flaky, so behave like a real rotating QR:
    // re-scan with the CURRENT elapsedSeconds until the session completes.
    let session;
    for (let attempt = 0; attempt < 6; attempt++) {
      await new Promise((r) => setTimeout(r, 1100));
      const elapsedSeconds = Math.max(
        1,
        Math.round((Date.now() - createdAt) / 1000)
      );
      const { deviceLink } = await buildDeviceLink(
        {
          deviceLinkBase: init.deviceLinkBase,
          deviceLinkType: "QR",
          elapsedSeconds,
          sessionToken: init.sessionToken,
          sessionType: "auth",
        },
        {
          schemeName: DEMO_SCHEME_NAME,
          rpChallengeB64,
          relyingPartyName: DEMO_RP_NAME,
          interactionsB64,
          initialCallbackUrl: "",
        },
        init.sessionSecret
      );
      await mockScanDeviceLink({
        documentNumber: TEST_ACCOUNTS.deviceLinkOkDocument,
        deviceLink,
        flowType: "QR",
      });
      const status = await getSessionStatus(init.sessionID, 5_000);
      if (status.state === "COMPLETE") {
        session = status;
        break;
      }
    }
    if (!session) session = await pollUntilComplete(init.sessionID, 6);
    assertEquals(session.result?.endResult, "OK");
    assertEquals(session.signature?.flowType, "QR");

    const result = await verifyAuthenticationSession({
      session,
      schemeName: DEMO_SCHEME_NAME,
      rpChallengeB64,
      relyingPartyName: DEMO_RP_NAME,
      interactionsB64,
      trustedCaPems: SK_DEMO_CA_PEMS,
      initialCallbackUrl: "",
    });
    assert(result.ok, `live QR verification failed: ${JSON.stringify(result)}`);
    assertEquals(result.identity?.etsiIdentifier, "PNOEE-40404040009");
  },
});
