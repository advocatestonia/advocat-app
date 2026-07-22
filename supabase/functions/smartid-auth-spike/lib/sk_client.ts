// Thin HTTP client for the SK Smart-ID RP API v3 DEMO environment + mock service.
// Network-touching code lives here so everything else stays pure/testable.

import {
  DEMO_BASE_URL,
  DEMO_MOCK_URL,
  DEMO_RP_NAME,
  DEMO_RP_UUID,
  SESSION_POLL_TIMEOUT_MS,
} from "../config.ts";
import type { SessionStatus } from "./verify.ts";

export interface AuthInitCommon {
  rpChallengeB64: string;
  interactionsB64: string;
}

async function postJson(
  url: string,
  body: unknown
): Promise<{ status: number; json: unknown }> {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json: unknown = {};
  if (text.trim()) {
    try {
      json = JSON.parse(text);
    } catch {
      json = { raw: text.slice(0, 500) };
    }
  }
  return { status: res.status, json };
}

function authRequestBody(
  p: AuthInitCommon,
  extra: Record<string, unknown> = {}
) {
  return {
    relyingPartyUUID: DEMO_RP_UUID,
    relyingPartyName: DEMO_RP_NAME,
    certificateLevel: "QUALIFIED",
    signatureProtocol: "ACSP_V2",
    signatureProtocolParameters: {
      rpChallenge: p.rpChallengeB64,
      signatureAlgorithm: "rsassa-pss",
      signatureAlgorithmParameters: { hashAlgorithm: "SHA-512" },
    },
    interactions: p.interactionsB64,
    ...extra,
  };
}

/** POST /v3/authentication/notification/etsi/{etsi} → { sessionID } */
export async function startNotificationAuth(
  etsiIdentifier: string,
  p: AuthInitCommon
): Promise<{ sessionID: string }> {
  const { status, json } = await postJson(
    `${DEMO_BASE_URL}/v3/authentication/notification/etsi/${etsiIdentifier}`,
    authRequestBody(p, { vcType: "numeric4" })
  );
  if (status !== 200)
    throw new Error(
      `notification init failed HTTP ${status}: ${JSON.stringify(json)}`
    );
  return json as { sessionID: string };
}

export interface DeviceLinkInitResponse {
  sessionID: string;
  sessionToken: string;
  sessionSecret: string;
  deviceLinkBase: string;
}

/** POST /v3/authentication/device-link/anonymous → session + link material */
export async function startAnonymousDeviceLinkAuth(
  p: AuthInitCommon
): Promise<DeviceLinkInitResponse> {
  const { status, json } = await postJson(
    `${DEMO_BASE_URL}/v3/authentication/device-link/anonymous`,
    authRequestBody(p)
  );
  if (status !== 200)
    throw new Error(
      `device-link init failed HTTP ${status}: ${JSON.stringify(json)}`
    );
  return json as DeviceLinkInitResponse;
}

/** GET /v3/session/{id} — single long-poll. */
export async function getSessionStatus(
  sessionId: string,
  timeoutMs = SESSION_POLL_TIMEOUT_MS
): Promise<SessionStatus> {
  const res = await fetch(
    `${DEMO_BASE_URL}/v3/session/${sessionId}?timeoutMs=${timeoutMs}`
  );
  if (!res.ok) throw new Error(`session poll failed HTTP ${res.status}`);
  return (await res.json()) as SessionStatus;
}

/**
 * DEMO-ONLY: POST /mock/device-link — simulates the user scanning the QR with
 * the given auto-responding test document number.
 */
export async function mockScanDeviceLink(opts: {
  documentNumber: string;
  deviceLink: string;
  flowType: "QR" | "Web2App" | "App2App";
}): Promise<void> {
  const { status, json } = await postJson(`${DEMO_MOCK_URL}/device-link`, opts);
  if (status !== 200)
    throw new Error(
      `mock device-link failed HTTP ${status}: ${JSON.stringify(json)}`
    );
}
