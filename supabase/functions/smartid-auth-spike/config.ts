// smartid-auth-spike — SK Smart-ID DEMO environment constants.
// -----------------------------------------------------------------------------
// SPIKE ONLY — NOT WIRED TO PROD AUTH. See docs/SMARTID_SPIKE_2026-07.md.
//
// Values verified live against SK demo on 2026-07-17:
//   - base URL + RP credentials: https://sk-eid.github.io/smart-id-documentation/environments.html
//   - schemeName "smart-id-demo" empirically confirmed: ACSP_V2 signature from a
//     live demo session verifies ONLY with "smart-id-demo" (fails with "smart-id").
// -----------------------------------------------------------------------------

/** RP API v3 base for the FREE SK demo environment. */
export const DEMO_BASE_URL = "https://sid.demo.sk.ee/smart-id-rp";

/** Mock service ("autosigner") that simulates the phone for device-link flows. */
export const DEMO_MOCK_URL = "https://sid.demo.sk.ee/mock";

/** Public demo relying-party credentials published by SK (free, no registration). */
export const DEMO_RP_UUID = "00000000-0000-4000-8000-000000000000";
export const DEMO_RP_NAME = "DEMO";

/**
 * Scheme name — first field of both the ACSP_V2 payload and the authCode payload.
 * LIVE = "smart-id", DEMO = "smart-id-demo". Getting this wrong is the #1
 * silent-failure trap: device-link sessions end PROTOCOL_FAILURE/TIMEOUT and
 * ACSP_V2 verification fails.
 */
export const DEMO_SCHEME_NAME = "smart-id-demo";

/** Auto-responding demo test accounts (no phone needed). */
export const TEST_ACCOUNTS = {
  /** Notification flow, auto-OK, cert by TEST of SK ID Solutions EID-Q 2024E. */
  notificationOkEtsi: "PNOEE-40504040001",
  notificationOkDocument: "PNOEE-40504040001-DEM2-Q",
  /** Device-link flows via mock service, auto-OK. */
  deviceLinkOkDocument: "PNOEE-40404040009-MOCK-Q",
  /** Negative-path accounts (notification flow). */
  userRefusedEtsi: "PNOEE-30403039917",
  timeoutEtsi: "PNOEE-30403039983",
} as const;

/** Long-poll timeout we pass to GET /v3/session/{id}. */
export const SESSION_POLL_TIMEOUT_MS = 10_000;
