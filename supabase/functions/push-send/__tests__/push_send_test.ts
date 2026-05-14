// Deno tests for push-send (auth gate + fcm config gating).
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/push-send/__tests__/push_send_test.ts

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { checkCronSecret } from "../../deadline-radar-tick/auth_gate.ts";
import { __resetFcmCaches, isFcmConfigured, sendPush } from "../../_shared/fcm_push.ts";

Deno.test("PS-T01 — auth gate: rejects without secret", () => {
  const r = checkCronSecret(null, "real-secret");
  assertEquals(r.kind, "deny");
});

Deno.test("PS-T02 — auth gate: accepts matching secret", () => {
  const r = checkCronSecret("real-secret", "real-secret");
  assertEquals(r.kind, "allow");
});

Deno.test("PS-T10 — isFcmConfigured: false when env empty", () => {
  __resetFcmCaches();
  const oldA = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  const oldB = Deno.env.get("GOOGLE_APPLICATION_CREDENTIALS_JSON");
  Deno.env.delete("FCM_SERVICE_ACCOUNT_JSON");
  Deno.env.delete("GOOGLE_APPLICATION_CREDENTIALS_JSON");
  try {
    assertEquals(isFcmConfigured(), false);
  } finally {
    if (oldA) Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", oldA);
    if (oldB) Deno.env.set("GOOGLE_APPLICATION_CREDENTIALS_JSON", oldB);
    __resetFcmCaches();
  }
});

Deno.test("PS-T11 — isFcmConfigured: false when malformed JSON", () => {
  __resetFcmCaches();
  const old = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", "{not json");
  try {
    assertEquals(isFcmConfigured(), false);
  } finally {
    if (old !== undefined) Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", old);
    else Deno.env.delete("FCM_SERVICE_ACCOUNT_JSON");
    __resetFcmCaches();
  }
});

Deno.test("PS-T12 — isFcmConfigured: false when JSON missing required fields", () => {
  __resetFcmCaches();
  const old = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  Deno.env.set(
    "FCM_SERVICE_ACCOUNT_JSON",
    JSON.stringify({ client_email: "x@y.z" }),
  );
  try {
    assertEquals(isFcmConfigured(), false);
  } finally {
    if (old !== undefined) Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", old);
    else Deno.env.delete("FCM_SERVICE_ACCOUNT_JSON");
    __resetFcmCaches();
  }
});

Deno.test("PS-T20 — sendPush: returns fcm_not_configured when env empty", async () => {
  __resetFcmCaches();
  const oldA = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  const oldB = Deno.env.get("GOOGLE_APPLICATION_CREDENTIALS_JSON");
  Deno.env.delete("FCM_SERVICE_ACCOUNT_JSON");
  Deno.env.delete("GOOGLE_APPLICATION_CREDENTIALS_JSON");
  try {
    const r = await sendPush({
      fcmToken: "fake-token",
      title: "Test",
      body: "Test",
    });
    assertEquals(r.ok, false);
    assertEquals(r.error, "fcm_not_configured");
  } finally {
    if (oldA) Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", oldA);
    if (oldB) Deno.env.set("GOOGLE_APPLICATION_CREDENTIALS_JSON", oldB);
    __resetFcmCaches();
  }
});

Deno.test("PS-T21 — sendPush: returns missing_token_or_topic if both omitted", async () => {
  __resetFcmCaches();
  // Set a valid-shape service account so we get past the config gate.
  // We won't actually call FCM because the function bails at the
  // "missing_token_or_topic" check before the network call.
  const fakeSa = {
    client_email: "test@advocat-fake.iam.gserviceaccount.com",
    private_key:
      "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEF\n-----END PRIVATE KEY-----",
    project_id: "advocat-fake",
  };
  const old = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", JSON.stringify(fakeSa));
  try {
    const r = await sendPush({ title: "T", body: "B" });
    assertEquals(r.ok, false);
    assertEquals(r.error, "missing_token_or_topic");
  } finally {
    if (old !== undefined) Deno.env.set("FCM_SERVICE_ACCOUNT_JSON", old);
    else Deno.env.delete("FCM_SERVICE_ACCOUNT_JSON");
    __resetFcmCaches();
  }
});
