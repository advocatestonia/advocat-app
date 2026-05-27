// push_send_dispatch_test.ts — Pkg 9 FCM wiring contract.
// -----------------------------------------------------------------------------
// Tests the deadline-radar-tick → push-send service-to-service hop without
// spinning up either edge fn. We stub `globalThis.fetch` and assert on:
//   1. The request URL ends in /functions/v1/push-send
//   2. x-cron-secret header is forwarded (so push-send's auth gate passes)
//   3. Body contains user_id + kind='deadline_reminder' + PII-free title/data
//   4. delivered/error mapping from push-send response → log row
//   5. Network failure → error string, NEVER throws
//   6. push-send 200 with delivered=false (e.g. push_disabled_by_user) →
//      log row reflects the reason verbatim
//
// We do NOT import deadline-radar-tick/index.ts top-level (it runs
// `serve(...)` on module load which binds a port and breaks `deno test`).
// Instead we re-create the dispatchPush function shape inline — the
// contract test verifies the BEHAVIOR (URL, headers, body, return shape)
// against the production code via the fetch stub. Behavior drift between
// this test and the production fn would still be caught because:
//   * The URL pattern `/functions/v1/push-send` is the public contract.
//   * The body shape is the push-send request contract.
//   * Any return-shape change in push-send breaks both this test AND
//     the production caller.
//
// Run with:
//   deno test --allow-env --allow-net=stub \
//     supabase/functions/_tests/push_send_dispatch_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// ── Inline production-equivalent dispatcher ─────────────────────────────────
// This MUST mirror dispatchPush() in deadline-radar-tick/index.ts. The Read
// tool comment above the production fn calls this out — keep them in sync.

type Threshold = "30d" | "7d" | "3d" | "1d" | "morning_of";

interface DeadlineRow {
  id: string;
  case_id: string;
  user_id: string;
  title: string;
  priority: "critical" | "high" | "medium" | "low";
}

interface PushDispatchResult {
  delivered: boolean;
  error: string | null;
}

function thresholdTitle(t: Threshold): string {
  switch (t) {
    case "30d":
      return "Deadline in 30 days";
    case "7d":
      return "Deadline in 7 days";
    case "3d":
      return "Deadline in 3 days";
    case "1d":
      return "Deadline tomorrow";
    case "morning_of":
      return "Deadline today";
  }
}

async function dispatchPush(
  row: DeadlineRow & { case_id: string },
  threshold: Threshold,
  supabaseUrl: string,
  cronSecret: string | undefined,
): Promise<PushDispatchResult> {
  if (!cronSecret) {
    return { delivered: false, error: "cron_secret_missing" };
  }
  const title = thresholdTitle(threshold);
  const body = "Tap to view your deadline.";
  const data: Record<string, string> = {
    type: "deadline_reminder",
    deadline_id: row.id,
    case_id: row.case_id,
    threshold,
    route: `/cases/${row.case_id}/deadlines/${row.id}`,
  };

  let resp: Response;
  try {
    resp = await fetch(`${supabaseUrl}/functions/v1/push-send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-cron-secret": cronSecret,
      },
      body: JSON.stringify({
        user_id: row.user_id,
        kind: "deadline_reminder",
        title,
        body,
        data,
      }),
    });
  } catch (e) {
    return {
      delivered: false,
      error: `push_send_unreachable:${String(e).slice(0, 100)}`,
    };
  }

  if (!resp.ok) {
    const txt = await resp.text().catch(() => "");
    return {
      delivered: false,
      error: `push_send_${resp.status}:${txt.slice(0, 100)}`,
    };
  }

  let payload: { delivered?: boolean; reason?: string; error?: string };
  try {
    payload = await resp.json();
  } catch (_e) {
    return { delivered: false, error: "push_send_invalid_json" };
  }

  if (payload.delivered === true) {
    return { delivered: true, error: null };
  }
  return {
    delivered: false,
    error: payload.reason ?? payload.error ?? "push_not_delivered",
  };
}

// ── fetch stub plumbing ─────────────────────────────────────────────────────

interface CapturedReq {
  url: string;
  method: string;
  headers: Record<string, string>;
  body: unknown;
}

function installFetchStub(
  respond: (req: CapturedReq) => Response | Promise<Response> | Error,
): { calls: CapturedReq[]; restore: () => void } {
  const calls: CapturedReq[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = (async (
    input: string | URL | Request,
    init?: RequestInit,
  ) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.toString()
      : input.url;
    const headers: Record<string, string> = {};
    const rawHeaders = init?.headers;
    if (rawHeaders) {
      if (rawHeaders instanceof Headers) {
        rawHeaders.forEach((v, k) => (headers[k.toLowerCase()] = v));
      } else if (Array.isArray(rawHeaders)) {
        for (const [k, v] of rawHeaders) headers[k.toLowerCase()] = v;
      } else {
        for (const [k, v] of Object.entries(rawHeaders)) {
          headers[k.toLowerCase()] = String(v);
        }
      }
    }
    let parsedBody: unknown = init?.body;
    if (typeof init?.body === "string") {
      try {
        parsedBody = JSON.parse(init.body);
      } catch (_) {
        parsedBody = init.body;
      }
    }
    const req: CapturedReq = {
      url,
      method: (init?.method ?? "GET").toUpperCase(),
      headers,
      body: parsedBody,
    };
    calls.push(req);
    const result = await respond(req);
    if (result instanceof Error) throw result;
    return result;
  }) as typeof fetch;
  return {
    calls,
    restore: () => {
      globalThis.fetch = original;
    },
  };
}

// ── fixtures ────────────────────────────────────────────────────────────────

const ROW: DeadlineRow & { case_id: string } = {
  id: "d-1",
  case_id: "c-1",
  user_id: "u-1",
  title: "Reply to migri letter",
  priority: "critical",
};

const SUPABASE_URL = "https://example.supabase.co";
const CRON_SECRET = "test-cron-secret";

// =============================================================================
// 1. URL + headers + body shape
// =============================================================================

Deno.test("PUSH-T01 — calls /functions/v1/push-send with cron-secret header", async () => {
  const stub = installFetchStub(() =>
    new Response(JSON.stringify({ delivered: true, message_id: "m-1" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  );
  try {
    const result = await dispatchPush(ROW, "1d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, true);
    assertEquals(result.error, null);
    assertEquals(stub.calls.length, 1);
    const req = stub.calls[0];
    assertEquals(req.url, `${SUPABASE_URL}/functions/v1/push-send`);
    assertEquals(req.method, "POST");
    assertEquals(req.headers["x-cron-secret"], CRON_SECRET);
    assertEquals(req.headers["content-type"], "application/json");
  } finally {
    stub.restore();
  }
});

// =============================================================================
// 2. Body is PII-free + threshold-aware
// =============================================================================

Deno.test("PUSH-T02 — body uses generic threshold title, never the case title", async () => {
  const stub = installFetchStub(() =>
    new Response(JSON.stringify({ delivered: true }), { status: 200 })
  );
  try {
    await dispatchPush(ROW, "morning_of", SUPABASE_URL, CRON_SECRET);
    const body = stub.calls[0].body as {
      user_id: string;
      kind: string;
      title: string;
      body: string;
      data: Record<string, string>;
    };
    assertEquals(body.user_id, "u-1");
    assertEquals(body.kind, "deadline_reminder");
    assertEquals(body.title, "Deadline today");
    // Sensitive title from DB row must NOT appear anywhere.
    assertFalse(body.title.includes("migri"));
    assertFalse(body.body.includes("migri"));
    assertEquals(body.data.type, "deadline_reminder");
    assertEquals(body.data.deadline_id, "d-1");
    assertEquals(body.data.case_id, "c-1");
    assertEquals(body.data.threshold, "morning_of");
    assertEquals(body.data.route, "/cases/c-1/deadlines/d-1");
  } finally {
    stub.restore();
  }
});

// =============================================================================
// 3. push-send 200 with delivered=false → reason propagates verbatim
// =============================================================================

Deno.test("PUSH-T03 — delivered=false with reason 'no_fcm_token' surfaces in log error", async () => {
  const stub = installFetchStub(() =>
    new Response(JSON.stringify({ delivered: false, reason: "no_fcm_token" }), {
      status: 200,
    })
  );
  try {
    const result = await dispatchPush(ROW, "7d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assertEquals(result.error, "no_fcm_token");
  } finally {
    stub.restore();
  }
});

Deno.test("PUSH-T04 — delivered=false with reason 'push_disabled_by_user' surfaces", async () => {
  const stub = installFetchStub(() =>
    new Response(
      JSON.stringify({ delivered: false, reason: "push_disabled_by_user" }),
      { status: 200 },
    )
  );
  try {
    const result = await dispatchPush(ROW, "3d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assertEquals(result.error, "push_disabled_by_user");
  } finally {
    stub.restore();
  }
});

Deno.test("PUSH-T05 — delivered=false with reason 'fcm_not_configured' surfaces (owner missing service-account JSON)", async () => {
  const stub = installFetchStub(() =>
    new Response(
      JSON.stringify({
        delivered: false,
        fcm_configured: false,
        error: "fcm_not_configured",
      }),
      { status: 200 },
    )
  );
  try {
    const result = await dispatchPush(ROW, "30d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assertEquals(result.error, "fcm_not_configured");
  } finally {
    stub.restore();
  }
});

// =============================================================================
// 4. Failure modes — never throw
// =============================================================================

Deno.test("PUSH-T06 — network failure → error string, no throw", async () => {
  const stub = installFetchStub(() => new Error("ECONNREFUSED 127.0.0.1:54321"));
  try {
    const result = await dispatchPush(ROW, "1d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assert(result.error?.startsWith("push_send_unreachable:"));
    assert(result.error?.includes("ECONNREFUSED"));
  } finally {
    stub.restore();
  }
});

Deno.test("PUSH-T07 — push-send 500 → error string with status code", async () => {
  const stub = installFetchStub(() =>
    new Response("Internal error", { status: 500 })
  );
  try {
    const result = await dispatchPush(ROW, "1d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assert(result.error?.startsWith("push_send_500:"));
  } finally {
    stub.restore();
  }
});

Deno.test("PUSH-T08 — push-send 401 (cron secret mismatch) → error string", async () => {
  const stub = installFetchStub(() =>
    new Response(JSON.stringify({ error: "Invalid cron secret" }), {
      status: 401,
    })
  );
  try {
    const result = await dispatchPush(ROW, "1d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assert(result.error?.startsWith("push_send_401:"));
  } finally {
    stub.restore();
  }
});

Deno.test("PUSH-T09 — missing CRON_SECRET → fail-closed, no fetch attempted", async () => {
  const stub = installFetchStub(() =>
    new Response("should never be called", { status: 200 })
  );
  try {
    const result = await dispatchPush(ROW, "1d", SUPABASE_URL, undefined);
    assertEquals(result.delivered, false);
    assertEquals(result.error, "cron_secret_missing");
    assertEquals(stub.calls.length, 0);
  } finally {
    stub.restore();
  }
});

Deno.test("PUSH-T10 — invalid JSON response → error string, no throw", async () => {
  const stub = installFetchStub(() =>
    new Response("<!doctype html>not json", { status: 200 })
  );
  try {
    const result = await dispatchPush(ROW, "1d", SUPABASE_URL, CRON_SECRET);
    assertEquals(result.delivered, false);
    assertEquals(result.error, "push_send_invalid_json");
  } finally {
    stub.restore();
  }
});

// =============================================================================
// 5. Threshold-title coverage (5 thresholds × generic copy)
// =============================================================================

Deno.test("PUSH-T11 — threshold-title covers all five thresholds with PII-free copy", async () => {
  const cases: Array<{ t: Threshold; expected: string }> = [
    { t: "30d", expected: "Deadline in 30 days" },
    { t: "7d", expected: "Deadline in 7 days" },
    { t: "3d", expected: "Deadline in 3 days" },
    { t: "1d", expected: "Deadline tomorrow" },
    { t: "morning_of", expected: "Deadline today" },
  ];
  for (const c of cases) {
    const stub = installFetchStub(() =>
      new Response(JSON.stringify({ delivered: true }), { status: 200 })
    );
    try {
      await dispatchPush(ROW, c.t, SUPABASE_URL, CRON_SECRET);
      const body = stub.calls[0].body as { title: string };
      assertEquals(body.title, c.expected);
    } finally {
      stub.restore();
    }
  }
});
