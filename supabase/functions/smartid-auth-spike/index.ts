// smartid-auth-spike — WORKING SPIKE against the FREE SK Smart-ID DEMO env.
// =============================================================================
// ⚠️ SPIKE ONLY. NOT DEPLOYED, NOT WIRED TO PROD AUTH, NO DB WRITES.
// Purpose: prove the full Smart-ID RP API v3 round-trip (session init →
// poll → ACSP_V2 signature verification → cert chain check → identity) runs
// inside a Deno/Supabase edge function, to feed the AUTH-ARCH decision
// (path A broker vs path B own bridge). See docs/SMARTID_SPIKE_2026-07.md.
//
// Run locally (no JWT, no DB):
//   supabase functions serve smartid-auth-spike --no-verify-jwt
// or plain Deno:
//   deno run --allow-net supabase/functions/smartid-auth-spike/index.ts
//
// Endpoints (all relative to the function root):
//   POST /start          {flow:"notification"|"qr", etsi?}    → session + VC
//   GET  /qr-link?id=…                                        → current QR device link
//   POST /simulate-app   {id, documentNumber?}                → mock "scan" (demo only)
//   GET  /result?id=…                                         → poll + FULL verification
//   POST /mint-session                                        → 501 (documented, not wired)
//
// Happy-path demo (auto-responding test account, no phone needed):
//   1. POST /start {"flow":"notification"}        → returns verificationCode
//   2. GET  /result?id=<spikeSessionId>           → endResult OK + verified identity
// Device-link QR path:
//   1. POST /start {"flow":"qr"}
//   2. POST /simulate-app {"id":"<spikeSessionId>"}   (mock scans the QR)
//   3. GET  /result?id=<spikeSessionId>
// =============================================================================

import { DEMO_SCHEME_NAME, DEMO_RP_NAME, TEST_ACCOUNTS } from "./config.ts";
import { b64Encode, utf8 } from "./lib/b64.ts";
import { computeVerificationCode, generateRpChallenge } from "./lib/acsp.ts";
import { buildDeviceLink } from "./lib/devicelink.ts";
import {
  getSessionStatus,
  mockScanDeviceLink,
  startAnonymousDeviceLinkAuth,
  startNotificationAuth,
} from "./lib/sk_client.ts";
import { verifyAuthenticationSession } from "./lib/verify.ts";
import { SK_DEMO_CA_PEMS } from "./lib/sk_demo_ca.ts";

// In-memory session store. SPIKE ONLY — production needs a DB/KV row keyed by
// an opaque id, because edge-function isolates are stateless across requests.
interface SpikeSession {
  flow: "notification" | "qr";
  rpChallengeB64: string;
  interactionsB64: string;
  smartIdSessionId: string;
  createdAtMs: number;
  // device-link only:
  sessionToken?: string;
  sessionSecret?: string;
  deviceLinkBase?: string;
}
const sessions = new Map<string, SpikeSession>();

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { "Content-Type": "application/json", ...CORS },
  });
}

function interactionsFor(text: string): string {
  // Store & reuse this exact Base64 string — re-serializing the JSON later can
  // change bytes and break both authCode and ACSP_V2 verification.
  return b64Encode(
    utf8(JSON.stringify([{ type: "displayTextAndPIN", displayText60: text }]))
  );
}

async function handleStart(req: Request): Promise<Response> {
  const body = await req.json().catch(() => ({}));
  const flow = body.flow === "qr" ? "qr" : "notification";
  const { bytes: rpChallengeBytes, base64: rpChallengeB64 } =
    generateRpChallenge();
  const interactionsB64 = interactionsFor(
    body.displayText ?? "Advocat Smart-ID spike"
  );
  const id = crypto.randomUUID();

  if (flow === "notification") {
    const etsi = body.etsi ?? TEST_ACCOUNTS.notificationOkEtsi;
    const init = await startNotificationAuth(etsi, {
      rpChallengeB64,
      interactionsB64,
    });
    const verificationCode = await computeVerificationCode(rpChallengeBytes);
    sessions.set(id, {
      flow,
      rpChallengeB64,
      interactionsB64,
      smartIdSessionId: init.sessionID,
      createdAtMs: Date.now(),
    });
    return json({
      spikeSessionId: id,
      flow,
      etsi,
      // RP must display this; the Smart-ID app shows the same code.
      verificationCode,
      smartIdSessionId: init.sessionID,
      next: `GET /result?id=${id}`,
    });
  }

  const init = await startAnonymousDeviceLinkAuth({
    rpChallengeB64,
    interactionsB64,
  });
  sessions.set(id, {
    flow,
    rpChallengeB64,
    interactionsB64,
    smartIdSessionId: init.sessionID,
    createdAtMs: Date.now(),
    sessionToken: init.sessionToken,
    sessionSecret: init.sessionSecret,
    deviceLinkBase: init.deviceLinkBase,
  });
  return json({
    spikeSessionId: id,
    flow,
    smartIdSessionId: init.sessionID,
    deviceLinkBase: init.deviceLinkBase,
    note:
      "QR content changes every second; GET /qr-link?id=… returns the current link. " +
      "sessionSecret stays server-side.",
    next: [
      `GET /qr-link?id=${id}`,
      `POST /simulate-app {"id":"${id}"}`,
      `GET /result?id=${id}`,
    ],
  });
}

async function currentDeviceLink(s: SpikeSession): Promise<string> {
  const elapsedSeconds = Math.max(
    1,
    Math.floor((Date.now() - s.createdAtMs) / 1000)
  );
  const { deviceLink } = await buildDeviceLink(
    {
      deviceLinkBase: s.deviceLinkBase!,
      deviceLinkType: "QR",
      elapsedSeconds,
      sessionToken: s.sessionToken!,
      sessionType: "auth",
    },
    {
      schemeName: DEMO_SCHEME_NAME,
      rpChallengeB64: s.rpChallengeB64,
      relyingPartyName: DEMO_RP_NAME,
      interactionsB64: s.interactionsB64,
      initialCallbackUrl: "", // QR flow: must be empty
    },
    s.sessionSecret!
  );
  return deviceLink;
}

async function handleQrLink(url: URL): Promise<Response> {
  const s = sessions.get(url.searchParams.get("id") ?? "");
  if (!s || s.flow !== "qr") return json({ error: "unknown qr session" }, 404);
  return json({ deviceLink: await currentDeviceLink(s) });
}

async function handleSimulateApp(req: Request): Promise<Response> {
  const body = await req.json().catch(() => ({}));
  const s = sessions.get(body.id ?? "");
  if (!s || s.flow !== "qr") return json({ error: "unknown qr session" }, 404);
  await mockScanDeviceLink({
    documentNumber: body.documentNumber ?? TEST_ACCOUNTS.deviceLinkOkDocument,
    deviceLink: await currentDeviceLink(s),
    flowType: "QR",
  });
  return json({
    ok: true,
    note: "mock accepted the device link; poll /result",
  });
}

async function handleResult(url: URL): Promise<Response> {
  const id = url.searchParams.get("id") ?? "";
  const s = sessions.get(id);
  if (!s) return json({ error: "unknown session" }, 404);

  const session = await getSessionStatus(s.smartIdSessionId);
  if (session.state !== "COMPLETE") return json({ state: session.state });

  const verification = await verifyAuthenticationSession({
    session,
    schemeName: DEMO_SCHEME_NAME,
    rpChallengeB64: s.rpChallengeB64,
    relyingPartyName: DEMO_RP_NAME,
    interactionsB64: s.interactionsB64,
    trustedCaPems: SK_DEMO_CA_PEMS,
    initialCallbackUrl: "", // QR + Notification flows both sign an empty callback field
  });

  return json({
    state: session.state,
    endResult: session.result?.endResult,
    verification,
    // identity is only present when signature + chain + validity all passed
  });
}

// Path B session-minting (DOCUMENTED, intentionally NOT implemented):
// after `verification.ok`, a prod bridge would look up/create the user by a
// deterministic identity key (e.g. smartid:PNOEE-40504040001) via the Supabase
// Admin API and mint a session with admin.generateLink({type:"magiclink"}) +
// verifyOtp({type:"email", token_hash}) server-side, returning access/refresh
// tokens to the client. Requires SERVICE_ROLE key + an identities table.
// Deliberately returns 501 here so nobody mistakes the spike for real auth.
function handleMintSession(): Response {
  return json(
    {
      error: "not implemented in spike (by design)",
      see: "docs/SMARTID_SPIKE_2026-07.md → 'Minting a Supabase session (path B)'",
    },
    501
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  // strip the function-name prefix when served by the supabase edge runtime
  const path = url.pathname.replace(/^\/smartid-auth-spike/, "") || "/";
  try {
    if (req.method === "POST" && path === "/start")
      return await handleStart(req);
    if (req.method === "GET" && path === "/qr-link")
      return await handleQrLink(url);
    if (req.method === "POST" && path === "/simulate-app")
      return await handleSimulateApp(req);
    if (req.method === "GET" && path === "/result")
      return await handleResult(url);
    if (req.method === "POST" && path === "/mint-session")
      return handleMintSession();
    return json(
      {
        spike: "smartid-auth-spike",
        endpoints: [
          "POST /start",
          "GET /qr-link",
          "POST /simulate-app",
          "GET /result",
        ],
      },
      path === "/" ? 200 : 404
    );
  } catch (e) {
    return json({ error: String(e instanceof Error ? e.message : e) }, 500);
  }
});
