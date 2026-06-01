// pdf-generator/__tests__/pdf_generator_test.ts
// -----------------------------------------------------------------------------
// Pure-logic + ownership-gate tests:
//   * markdownToHtml — stored-XSS guard (user/LLM markdown is escaped before
//     our own <strong>/<em> tags are emitted), plus the markdown subset.
//   * sanitiseTitle — ASCII slug / path-traversal safety.
//   * verifyCaseOwnership — IDOR regression: a case_documents row may only be
//     planted under a case the AUTHENTICATED user owns. The service-role
//     insert bypasses RLS, so this is the only gate. Guards the forgery class
//     where a forged case_id surfaces the caller's document in a victim's case.
//
// Run:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/pdf-generator/__tests__/pdf_generator_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  markdownToHtml,
  sanitiseTitle,
  verifyCaseOwnership,
} from "../index.ts";

// ─── markdownToHtml — XSS guard ──────────────────────────────────────────

Deno.test("MD-XSS-01 — raw <script> is HTML-escaped, never emitted as a tag", () => {
  const html = markdownToHtml("hello <script>alert(1)</script> world");
  assert(!html.includes("<script>"), "literal <script> must not survive");
  assertStringIncludes(html, "&lt;script&gt;");
});

Deno.test("MD-XSS-02 — img onerror handler is neutralised", () => {
  const html = markdownToHtml(`<img src=x onerror="alert(1)">`);
  assert(!html.includes("<img"), "literal <img> must not survive");
  assertStringIncludes(html, "&lt;img");
});

Deno.test("MD-XSS-03 — only our own strong/em tags are real tags", () => {
  const html = markdownToHtml("**bold** and *italic* and <b>evil</b>");
  assertStringIncludes(html, "<strong>bold</strong>");
  assertStringIncludes(html, "<em>italic</em>");
  // The user's literal <b> must be escaped, not a live tag.
  assert(!html.includes("<b>evil</b>"));
  assertStringIncludes(html, "&lt;b&gt;evil&lt;/b&gt;");
});

Deno.test("MD-04 — headings, lists, paragraphs render", () => {
  const html = markdownToHtml("## Title\n\n- one\n- two\n\nbody text");
  assertStringIncludes(html, "<h2>Title</h2>");
  assertStringIncludes(html, "<ul>");
  assertStringIncludes(html, "<li>one</li>");
  assertStringIncludes(html, "<p>body text</p>");
});

// ─── sanitiseTitle ───────────────────────────────────────────────────────

Deno.test("SLUG-01 — path traversal characters are stripped", () => {
  const slug = sanitiseTitle("../../etc/passwd");
  assert(!slug.includes("/"), "slug must not contain slashes");
  assert(!slug.includes(".."), "slug must not contain ..");
});

Deno.test("SLUG-02 — empty/garbage title falls back to 'document'", () => {
  assertEquals(sanitiseTitle("***"), "document");
  assertEquals(sanitiseTitle(""), "document");
});

Deno.test("SLUG-03 — diacritics are folded to ASCII", () => {
  assertEquals(sanitiseTitle("Hääletus Tähtaeg"), "haaletus_tahtaeg");
});

// ─── verifyCaseOwnership — IDOR regression ───────────────────────────────

const USER = "11111111-1111-1111-1111-111111111111";
const CASE = "22222222-2222-2222-2222-222222222222";

/** Fake fetch capturing the URL and returning a scripted REST response. */
function fakeFetch(opts: {
  status?: number;
  rows?: Array<{ id: string }>;
  throwIt?: boolean;
}): { fn: typeof fetch; lastUrl: () => string } {
  let url = "";
  const fn = ((input: string | URL | Request): Promise<Response> => {
    url = String(input);
    if (opts.throwIt) return Promise.reject(new Error("network down"));
    const status = opts.status ?? 200;
    const body = JSON.stringify(opts.rows ?? []);
    return Promise.resolve(
      new Response(status === 200 ? body : "err", { status }),
    );
  }) as unknown as typeof fetch;
  return { fn, lastUrl: () => url };
}

Deno.test("OWN-01 — owned case returns owned=true and filters by BOTH id and user_id", async () => {
  const { fn, lastUrl } = fakeFetch({ rows: [{ id: CASE }] });
  const r = await verifyCaseOwnership(fn, USER, CASE);
  assertEquals(r, { owned: true, error: false });
  // Regression: the query MUST scope by user_id, not just id — otherwise it
  // is not an ownership check.
  assertStringIncludes(lastUrl(), `id=eq.${CASE}`);
  assertStringIncludes(lastUrl(), `user_id=eq.${USER}`);
});

Deno.test("OWN-02 — foreign/non-existent case returns owned=false (no rows)", async () => {
  const { fn } = fakeFetch({ rows: [] });
  const r = await verifyCaseOwnership(fn, USER, CASE);
  assertEquals(r, { owned: false, error: false });
});

Deno.test("OWN-03 — REST error fails CLOSED (error=true, owned=false)", async () => {
  const { fn } = fakeFetch({ status: 500 });
  const r = await verifyCaseOwnership(fn, USER, CASE);
  assertEquals(r, { owned: false, error: true });
});

Deno.test("OWN-04 — network throw fails CLOSED", async () => {
  const { fn } = fakeFetch({ throwIt: true });
  const r = await verifyCaseOwnership(fn, USER, CASE);
  assertEquals(r, { owned: false, error: true });
});
