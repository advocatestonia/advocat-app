// gmail-label/__tests__/gmail_label_test.ts
// -----------------------------------------------------------------------------
// Pure-function tests for the gmail-label edge function. The HTTP handler
// itself depends on the Deno runtime + Supabase client; we exercise:
//
//   - sanitiseThreadId / sanitiseLabels — input validation
//   - resolveLabelId      — system passthrough, custom create-if-missing
//   - applyLabels         — happy path + Gmail error throws
//
// Network calls are intercepted by stubbing globalThis.fetch.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/gmail-label/__tests__/gmail_label_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyLabels,
  resolveLabelId,
  sanitiseGmailThreadId,
  sanitiseLabels,
  sanitiseThreadId,
  sanitiseUuid,
} from "../labels.ts";

// -----------------------------------------------------------------------------
// Fetch stub helper
// -----------------------------------------------------------------------------

interface RecordedCall {
  url: string;
  init?: RequestInit;
}

function withFetchStub(
  responder: (url: string, init?: RequestInit) => Response | Promise<Response>,
  body: () => Promise<void>,
): Promise<RecordedCall[]> {
  const calls: RecordedCall[] = [];
  const original = globalThis.fetch;
  // deno-lint-ignore no-explicit-any
  globalThis.fetch = (async (input: any, init?: RequestInit) => {
    const url = typeof input === "string" ? input : input.url;
    calls.push({ url, init });
    return await responder(url, init);
  }) as typeof fetch;
  return body()
    .finally(() => {
      globalThis.fetch = original;
    })
    .then(() => calls);
}

// =============================================================================
// sanitiseThreadId
// =============================================================================

Deno.test("sanitiseThreadId — accepts hex-ish ids", () => {
  assertEquals(sanitiseThreadId("18a9b3c4d5e6f"), "18a9b3c4d5e6f");
  assertEquals(sanitiseThreadId("  18a9b3c4d5e6f  "), "18a9b3c4d5e6f");
  assertEquals(sanitiseThreadId("thread_id-with-dashes"), "thread_id-with-dashes");
});

Deno.test("sanitiseThreadId — rejects bad shapes", () => {
  assertEquals(sanitiseThreadId(""), null);
  assertEquals(sanitiseThreadId(null), null);
  assertEquals(sanitiseThreadId(123), null);
  assertEquals(sanitiseThreadId("with spaces"), null);
  assertEquals(sanitiseThreadId("../../etc/passwd"), null);
  assertEquals(sanitiseThreadId("thread\r\ninjected"), null);
  assertEquals(sanitiseThreadId("a".repeat(201)), null);
});

// =============================================================================
// sanitiseUuid
// =============================================================================

Deno.test("sanitiseUuid — accepts canonical lowercase v4", () => {
  assertEquals(
    sanitiseUuid("a1b2c3d4-e5f6-7890-abcd-ef1234567890"),
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  );
});

Deno.test("sanitiseUuid — lowercases input", () => {
  assertEquals(
    sanitiseUuid("A1B2C3D4-E5F6-7890-ABCD-EF1234567890"),
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  );
});

Deno.test("sanitiseUuid — rejects non-uuid", () => {
  assertEquals(sanitiseUuid("not-a-uuid"), null);
  assertEquals(sanitiseUuid(""), null);
  assertEquals(sanitiseUuid(null), null);
  assertEquals(sanitiseUuid(123), null);
});

// =============================================================================
// sanitiseGmailThreadId
// =============================================================================

Deno.test("sanitiseGmailThreadId — accepts hex-ish ids", () => {
  assertEquals(sanitiseGmailThreadId("18a9b3c4d5e6f"), "18a9b3c4d5e6f");
});

Deno.test("sanitiseGmailThreadId — rejects bad shapes", () => {
  assertEquals(sanitiseGmailThreadId(""), null);
  assertEquals(sanitiseGmailThreadId("with space"), null);
  assertEquals(sanitiseGmailThreadId(null), null);
});

// =============================================================================
// sanitiseLabels
// =============================================================================

Deno.test("sanitiseLabels — strips bad entries, dedupes", () => {
  assertEquals(
    sanitiseLabels(["INBOX", "advocat:auto-archived", "INBOX", "  "]),
    ["INBOX", "advocat:auto-archived"],
  );
});

Deno.test("sanitiseLabels — non-array → []", () => {
  assertEquals(sanitiseLabels("INBOX"), []);
  assertEquals(sanitiseLabels(null), []);
  assertEquals(sanitiseLabels({}), []);
});

Deno.test("sanitiseLabels — rejects control chars + over-length", () => {
  assertEquals(sanitiseLabels(["valid", "bad\nlabel"]), ["valid"]);
  assertEquals(sanitiseLabels(["x".repeat(101)]), []);
});

// =============================================================================
// resolveLabelId
// =============================================================================

Deno.test("resolveLabelId — system labels round-trip without API call", async () => {
  let called = 0;
  await withFetchStub(
    () => {
      called++;
      return new Response("{}", { status: 200 });
    },
    async () => {
      const id = await resolveLabelId("token", "INBOX");
      assertEquals(id, "INBOX");
    },
  );
  assertEquals(called, 0);
});

Deno.test("resolveLabelId — existing custom label returns its id", async () => {
  await withFetchStub(
    (url) => {
      if (url.endsWith("/users/me/labels")) {
        return new Response(JSON.stringify({
          labels: [
            { id: "Label_INBOX", name: "INBOX" },
            { id: "Label_5483", name: "advocat:auto-archived" },
          ],
        }), { status: 200 });
      }
      throw new Error("unexpected fetch");
    },
    async () => {
      const id = await resolveLabelId("token", "advocat:auto-archived");
      assertEquals(id, "Label_5483");
    },
  );
});

Deno.test("resolveLabelId — missing custom label is created", async () => {
  let createCalled = false;
  await withFetchStub(
    (url, init) => {
      if (url.endsWith("/users/me/labels") && (!init || init.method !== "POST")) {
        return new Response(JSON.stringify({ labels: [] }), { status: 200 });
      }
      if (url.endsWith("/users/me/labels") && init?.method === "POST") {
        createCalled = true;
        const body = JSON.parse(init.body as string);
        assertEquals(body.name, "advocat:auto-archived");
        return new Response(JSON.stringify({
          id: "Label_NEW", name: body.name,
        }), { status: 200 });
      }
      throw new Error(`unexpected ${url}`);
    },
    async () => {
      const id = await resolveLabelId("token", "advocat:auto-archived");
      assertEquals(id, "Label_NEW");
    },
  );
  assert(createCalled);
});

Deno.test("resolveLabelId — labels.list error throws", async () => {
  await withFetchStub(
    () => new Response("forbidden", { status: 403 }),
    async () => {
      await assertRejects(() => resolveLabelId("token", "custom"));
    },
  );
});

// =============================================================================
// applyLabels
// =============================================================================

Deno.test("applyLabels — full flow: resolve + threads.modify", async () => {
  const calls = await withFetchStub(
    (url, init) => {
      if (url.endsWith("/users/me/labels")) {
        return new Response(JSON.stringify({
          labels: [{ id: "Label_5483", name: "advocat:auto-archived" }],
        }), { status: 200 });
      }
      if (url.includes("/threads/") && url.endsWith("/modify")) {
        const body = JSON.parse(init?.body as string);
        // INBOX is system → passes through as id; custom → resolved.
        assert(body.addLabelIds.includes("Label_5483"));
        assert(body.removeLabelIds.includes("INBOX"));
        return new Response(
          JSON.stringify({ id: "thread-1", labelIds: ["Label_5483"] }),
          { status: 200 },
        );
      }
      throw new Error(`unexpected ${url}`);
    },
    async () => {
      const result = await applyLabels({
        accessToken: "tok",
        threadId: "thread-1",
        addLabels: ["advocat:auto-archived"],
        removeLabels: ["INBOX"],
      });
      assertEquals(result.applied, ["advocat:auto-archived"]);
      assertEquals(result.removed, ["INBOX"]);
      assertEquals(result.labelIds["INBOX"], "INBOX");
      assertEquals(result.labelIds["advocat:auto-archived"], "Label_5483");
    },
  );
  // 2 calls: labels.list (only the custom label triggers a list — INBOX
  // is system so it short-circuits) + threads.modify.
  assertEquals(calls.length, 2);
});

Deno.test("applyLabels — threads.modify failure throws", async () => {
  await withFetchStub(
    (url) => {
      if (url.endsWith("/users/me/labels")) {
        return new Response(JSON.stringify({ labels: [] }), { status: 200 });
      }
      return new Response("rate limit", { status: 429 });
    },
    async () => {
      await assertRejects(() =>
        applyLabels({
          accessToken: "tok",
          threadId: "thread-1",
          addLabels: [],
          removeLabels: ["INBOX"],
        })
      );
    },
  );
});

Deno.test("applyLabels — only-system labels skips labels.list", async () => {
  const calls = await withFetchStub(
    (url) => {
      if (url.endsWith("/users/me/labels")) {
        throw new Error("should NOT call labels.list for system-only");
      }
      return new Response(JSON.stringify({ ok: true }), { status: 200 });
    },
    async () => {
      await applyLabels({
        accessToken: "tok",
        threadId: "thread-1",
        addLabels: ["UNREAD"],
        removeLabels: ["INBOX"],
      });
    },
  );
  // Exactly one call: threads.modify.
  assertEquals(calls.length, 1);
  assert(calls[0].url.endsWith("/modify"));
});
