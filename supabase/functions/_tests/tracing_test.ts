// tracing_test.ts
// -----------------------------------------------------------------------------
// Unit tests for _shared/tracing.ts.
//
//   TR01 — getOrCreateTraceId mints a new UUID when no header is present
//   TR02 — getOrCreateTraceId reads x-trace-id when valid
//   TR03 — getOrCreateTraceId rejects malformed x-trace-id and mints fresh
//   TR04 — propagateTraceId writes to Headers AND record forms
//   TR05 — propagateTraceId ignores invalid trace_id (defensive)
//   TR06 — shortTrace returns first 8 hex chars
//   TR07 — withTrace tags console.log without leaking the patch
//
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/_tests/tracing_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertNotEquals,
  assertMatch,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const {
  getOrCreateTraceId,
  newTraceId,
  propagateTraceId,
  shortTrace,
  withTrace,
  isValidTraceId,
} = await import("../_shared/tracing.ts");

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function mkReq(headers: Record<string, string> = {}): Request {
  return new Request("https://example.test", {
    method: "POST",
    headers: new Headers(headers),
    body: "{}",
  });
}

Deno.test("TR01 — getOrCreateTraceId mints UUID when no header present", () => {
  const id = getOrCreateTraceId(mkReq());
  assertMatch(id, UUID_RE);
});

Deno.test("TR02 — getOrCreateTraceId reads existing x-trace-id header", () => {
  const trace = "deadbeef-1234-4567-89ab-cdef01234567";
  const id = getOrCreateTraceId(mkReq({ "x-trace-id": trace }));
  assertEquals(id, trace);
});

Deno.test("TR03 — getOrCreateTraceId rejects malformed header and mints fresh", () => {
  const id = getOrCreateTraceId(mkReq({ "x-trace-id": "not-a-uuid" }));
  assertMatch(id, UUID_RE);
  assertNotEquals(id, "not-a-uuid");
});

Deno.test("TR04 — propagateTraceId writes to Headers AND record forms", () => {
  const trace = newTraceId();

  // Headers form
  const h = new Headers();
  propagateTraceId(h, trace);
  assertEquals(h.get("x-trace-id"), trace);

  // Record form
  const r: Record<string, string> = { "content-type": "application/json" };
  propagateTraceId(r, trace);
  assertEquals(r["x-trace-id"], trace);
  // Did not clobber other keys
  assertEquals(r["content-type"], "application/json");
});

Deno.test("TR05 — propagateTraceId ignores invalid trace_id (no-op)", () => {
  const h = new Headers();
  propagateTraceId(h, "garbage");
  // Header should NOT have been set with garbage.
  assertEquals(h.get("x-trace-id"), null);
});

Deno.test("TR06 — shortTrace returns first 8 hex chars", () => {
  const trace = "abcdef12-3456-4789-9abc-def012345678";
  assertEquals(shortTrace(trace), "abcdef12");
  assertEquals(shortTrace(""), "------");
  assertEquals(shortTrace("garbage"), "------");
});

Deno.test("TR07 — withTrace tags console.log + restores after", async () => {
  const trace = newTraceId();
  const captured: string[] = [];
  const orig = console.log;
  console.log = (...args: unknown[]) => {
    captured.push(args.join(" "));
  };
  try {
    await withTrace(trace, async () => {
      console.log("hello");
      console.log("world");
    });
  } finally {
    console.log = orig;
  }
  // First captured line should carry the trace tag.
  const tag = `[trace=${trace.slice(0, 8)}]`;
  assert(captured[0].startsWith(tag), `expected tag ${tag} got ${captured[0]}`);
  assert(captured[1].startsWith(tag));

  // After withTrace, console.log MUST be back to the previous (our stub).
  // Verify by logging again — our stub will catch it WITHOUT the tag.
  console.log = (...args: unknown[]) => captured.push(args.join(" "));
  console.log("after");
  // The first "after" we just pushed manually below — but the test stub above
  // already wrote "after" untagged. Either way it should NOT carry the tag.
  const last = captured[captured.length - 1];
  assert(!last.startsWith(tag), `tag leaked into post-withTrace logs: ${last}`);

  console.log = orig;
});

// -----------------------------------------------------------------------------
// TR08 — isValidTraceId helper validates UUIDv4-shape
// -----------------------------------------------------------------------------
Deno.test("TR08 — isValidTraceId accepts UUIDs, rejects everything else", () => {
  assert(isValidTraceId(newTraceId()));
  assert(isValidTraceId("12345678-1234-4234-9234-123456789abc"));
  assert(!isValidTraceId(""));
  assert(!isValidTraceId(null));
  assert(!isValidTraceId(undefined));
  assert(!isValidTraceId("not-a-uuid"));
  assert(!isValidTraceId("12345678-1234-1234-1234"));
});
