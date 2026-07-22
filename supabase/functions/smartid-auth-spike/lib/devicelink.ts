// Device-link (QR / Web2App / App2App) construction + authCode HMAC.
// Spec: rp-api/device_link_flows.html + rp-api/authcode.html.
// authCode validated live against SK demo core via the mock service
// (wrong schemeName ⇒ endResult PROTOCOL_FAILURE — the core does check it).

import { b64Decode, b64UrlEncode, utf8 } from "./b64.ts";

export interface DeviceLinkParams {
  deviceLinkBase: string; // from session init response, used as-is
  deviceLinkType: "QR" | "Web2App" | "App2App";
  /** REQUIRED for QR (whole seconds since session creation), MUST be absent for Web2App/App2App. */
  elapsedSeconds?: number;
  sessionToken: string; // from session init response, used as-is
  sessionType: "auth" | "sign" | "cert";
  version?: string; // currently "1.0"
  lang?: string; // ISO 639-2, e.g. "eng"
}

/** Device link without the trailing authCode. Parameter ORDER IS NORMATIVE. */
export function buildUnprotectedDeviceLink(p: DeviceLinkParams): string {
  const version = p.version ?? "1.0";
  const lang = p.lang ?? "eng";
  const parts = [`deviceLinkType=${p.deviceLinkType}`];
  if (p.deviceLinkType === "QR") {
    if (p.elapsedSeconds === undefined) {
      throw new Error("QR device link requires elapsedSeconds");
    }
    parts.push(`elapsedSeconds=${p.elapsedSeconds}`);
  }
  parts.push(
    `sessionToken=${p.sessionToken}`,
    `sessionType=${p.sessionType}`,
    `version=${version}`,
    `lang=${lang}`
  );
  return `${p.deviceLinkBase}?${parts.join("&")}`;
}

export interface AuthCodePayloadParams {
  schemeName: string; // "smart-id" LIVE / "smart-id-demo" DEMO
  rpChallengeB64: string; // Base64, as sent at init
  relyingPartyName: string; // plain; Base64-encoded here
  brokeredRpName?: string; // plain; empty when not brokering
  interactionsB64: string; // the EXACT Base64 string sent at init
  initialCallbackUrl?: string; // empty for QR
  unprotectedDeviceLink: string;
}

/**
 * Authentication-session authCode payload:
 *   schemeName|ACSP_V2|rpChallenge|B64(relyingPartyName)|B64(brokeredRpName)|
 *   interactions|initialCallbackUrl|unprotectedDeviceLink
 */
export function buildAuthCodePayload(p: AuthCodePayloadParams): string {
  const enc = (s: string) => (s ? b64EncodeUtf8(s) : "");
  return [
    p.schemeName,
    "ACSP_V2",
    p.rpChallengeB64,
    b64EncodeUtf8(p.relyingPartyName),
    enc(p.brokeredRpName ?? ""),
    p.interactionsB64,
    p.initialCallbackUrl ?? "",
    p.unprotectedDeviceLink,
  ].join("|");
}

function b64EncodeUtf8(s: string): string {
  let bin = "";
  const bytes = utf8(s);
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
}

/** authCode := BASE64URL(HMAC-SHA256(BASE64-DECODE(sessionSecret), UTF8(payload))), no padding. */
export async function computeAuthCode(
  sessionSecretB64: string,
  payload: string
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    b64Decode(sessionSecretB64).slice(),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const mac = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, utf8(payload).slice())
  );
  return b64UrlEncode(mac);
}

/** Full device link = unprotected link + computed authCode. */
export async function buildDeviceLink(
  linkParams: DeviceLinkParams,
  payloadParams: Omit<AuthCodePayloadParams, "unprotectedDeviceLink">,
  sessionSecretB64: string
): Promise<{
  deviceLink: string;
  unprotectedDeviceLink: string;
  authCode: string;
}> {
  const unprotectedDeviceLink = buildUnprotectedDeviceLink(linkParams);
  const payload = buildAuthCodePayload({
    ...payloadParams,
    unprotectedDeviceLink,
  });
  const authCode = await computeAuthCode(sessionSecretB64, payload);
  return {
    deviceLink: `${unprotectedDeviceLink}&authCode=${authCode}`,
    unprotectedDeviceLink,
    authCode,
  };
}
