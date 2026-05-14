// Deno tests for weekly-digest-send/digest_logic.ts
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/weekly-digest-send/__tests__/digest_logic_test.ts

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildDigestData,
  daysBetween,
  deadlinesIn14Days,
  nearestDeadline,
  pickLang,
  safeSubject,
  suggestedActions,
  summariseInsight,
} from "../digest_logic.ts";
import { renderDigest } from "../../_shared/retention_templates.ts";

const T0 = new Date("2026-05-14T08:00:00Z");

Deno.test("WD-T01 — daysBetween: same day = 0", () => {
  assertEquals(
    daysBetween(new Date("2026-05-14T00:00:00Z"), new Date("2026-05-14T23:00:00Z")),
    0,
  );
});

Deno.test("WD-T02 — daysBetween: 7 days forward = 7", () => {
  assertEquals(
    daysBetween(new Date("2026-05-14T00:00:00Z"), new Date("2026-05-21T00:00:00Z")),
    7,
  );
});

Deno.test("WD-T03 — daysBetween: negative for past = -3", () => {
  assertEquals(
    daysBetween(new Date("2026-05-14T00:00:00Z"), new Date("2026-05-11T00:00:00Z")),
    -3,
  );
});

Deno.test("WD-T04 — nearestDeadline: picks soonest active", () => {
  const d = nearestDeadline(
    [
      { title: "Far", deadline_at: "2026-06-01T00:00:00Z", status: "active" },
      { title: "Soon", deadline_at: "2026-05-15T00:00:00Z", status: "active" },
      { title: "Done", deadline_at: "2026-05-14T01:00:00Z", status: "completed" },
    ],
    T0,
  );
  assertExists(d);
  assertEquals(d?.title, "Soon");
});

Deno.test("WD-T05 — nearestDeadline: missed deadlines also count", () => {
  const d = nearestDeadline(
    [
      { title: "Missed", deadline_at: "2026-05-10T00:00:00Z", status: "missed" },
      { title: "Active", deadline_at: "2026-06-01T00:00:00Z", status: "active" },
    ],
    T0,
  );
  assertEquals(d?.title, "Missed");
  assert((d?.days ?? 0) < 0);
});

Deno.test("WD-T06 — nearestDeadline: empty list returns null", () => {
  assertEquals(nearestDeadline([], T0), null);
});

Deno.test("WD-T07 — deadlinesIn14Days: excludes overdue + far-future", () => {
  const list = deadlinesIn14Days(
    [
      { title: "Past", deadline_at: "2026-05-10T00:00:00Z", status: "active" },
      { title: "Today", deadline_at: "2026-05-14T18:00:00Z", status: "active" },
      { title: "Week", deadline_at: "2026-05-20T00:00:00Z", status: "active" },
      { title: "Future", deadline_at: "2026-06-01T00:00:00Z", status: "active" },
      { title: "Missed", deadline_at: "2026-05-15T00:00:00Z", status: "missed" },
    ],
    T0,
  );
  // Only Today (0d) + Week (6d) qualify
  assertEquals(list.length, 2);
  assertEquals(list[0].title, "Today");
  assertEquals(list[1].title, "Week");
});

Deno.test("WD-T08 — deadlinesIn14Days: empty list returns []", () => {
  assertEquals(deadlinesIn14Days([], T0), []);
});

Deno.test("WD-T09 — suggestedActions: urgent deadlines + insights surfaces both", () => {
  const a = suggestedActions({
    upcomingDeadlines: [{ daysAway: 2 }, { daysAway: 5 }],
    newInsights: 1,
    activeCases: 2,
    lang: "en",
  });
  assertEquals(a.length, 2);
  assert(a[0].includes("2"));
  assert(a[1].toLowerCase().includes("ai") || a[1].toLowerCase().includes("analysis"));
});

Deno.test("WD-T10 — suggestedActions: quiet week → single fallback", () => {
  const a = suggestedActions({
    upcomingDeadlines: [],
    newInsights: 0,
    activeCases: 1,
    lang: "en",
  });
  assertEquals(a.length, 1);
});

Deno.test("WD-T11 — suggestedActions: caps at 3", () => {
  const a = suggestedActions({
    upcomingDeadlines: [{ daysAway: 1 }, { daysAway: 2 }],
    newInsights: 5,
    activeCases: 3,
    lang: "et",
  });
  assert(a.length <= 3);
});

Deno.test("WD-T12 — pickLang: ET, RU, FI, ee, default EN", () => {
  assertEquals(pickLang("et"), "et");
  assertEquals(pickLang("ru"), "ru");
  assertEquals(pickLang("fi"), "fi");
  assertEquals(pickLang("ee"), "et");
  assertEquals(pickLang("en"), "en");
  assertEquals(pickLang(""), "en");
  assertEquals(pickLang(null), "en");
  assertEquals(pickLang("xx"), "en");
});

Deno.test("WD-T13 — safeSubject: strips CRLF + caps", () => {
  const s = safeSubject("Hello\r\nWorld\t!");
  assert(!s.includes("\n"));
  assert(!s.includes("\r"));
  assert(!s.includes("\t"));
  const long = "A".repeat(500);
  assert(safeSubject(long).length <= 250);
});

Deno.test("WD-T14 — summariseInsight: caps at 200 chars", () => {
  const long = "X".repeat(500);
  const s = summariseInsight(long);
  assert(s.length <= 200);
  assert(s.endsWith("..."));
});

Deno.test("WD-T15 — summariseInsight: short stays short", () => {
  assertEquals(summariseInsight("Brief"), "Brief");
});

Deno.test("WD-T20 — buildDigestData: end-to-end shape", () => {
  const data = buildDigestData(
    {
      fullName: "Dmitri Sulga",
      email: "test@example.com",
      preferredLang: "et",
      activeCases: [
        {
          id: "c1",
          title: "Sulga v. Finland",
          status: "active",
          advice_digest: [
            {
              created_at: "2026-05-13T10:00:00Z",
              summary: "KHO valituslupa due 5.6.2026",
            },
          ],
        },
      ],
      allDeadlines: [
        {
          title: "KHO valituslupa",
          deadline_at: "2026-05-20T00:00:00Z",
          status: "active",
          case_id: "c1",
          case_title: "Sulga v. Finland",
        },
        {
          title: "Other",
          deadline_at: "2026-07-01T00:00:00Z",
          status: "active",
          case_id: "c1",
          case_title: "Sulga v. Finland",
        },
      ],
      lastDigestSentAt: "2026-05-07T08:00:00Z",
      appBaseUrl: "https://advocat.ee/app",
      unsubscribeToken: "00000000-0000-0000-0000-000000000001",
    },
    T0,
  );
  assertEquals(data.lang, "et");
  assertEquals(data.cases.length, 1);
  assertEquals(data.cases[0].nextDeadlineTitle, "KHO valituslupa");
  assertEquals(data.upcomingDeadlines.length, 1); // Only KHO is in 14d window
  assertEquals(data.newInsights.length, 1);
  assert(data.unsubscribeUrl.includes("u/00000000"));
  assert(data.suggestedActions.length >= 1);
});

Deno.test("WD-T21 — buildDigestData: excludes old insights", () => {
  const data = buildDigestData(
    {
      fullName: "A",
      email: "a@b.c",
      preferredLang: "en",
      activeCases: [
        {
          id: "c1",
          title: "Case",
          status: "active",
          advice_digest: [
            { created_at: "2026-04-01T00:00:00Z", summary: "old" },
            { created_at: "2026-05-13T00:00:00Z", summary: "new" },
          ],
        },
      ],
      allDeadlines: [],
      lastDigestSentAt: "2026-05-07T08:00:00Z",
      appBaseUrl: "https://advocat.ee/app",
      unsubscribeToken: "tok",
    },
    T0,
  );
  assertEquals(data.newInsights.length, 1);
  assertEquals(data.newInsights[0].summary, "new");
});

Deno.test("WD-T22 — buildDigestData: caps insights at 5", () => {
  const adviceList = Array.from({ length: 10 }, (_, i) => ({
    created_at: `2026-05-${10 + i}T00:00:00Z`,
    summary: `insight-${i}`,
  }));
  const data = buildDigestData(
    {
      fullName: "A",
      email: "a@b.c",
      preferredLang: "en",
      activeCases: [
        {
          id: "c1",
          title: "Case",
          status: "active",
          advice_digest: adviceList,
        },
      ],
      allDeadlines: [],
      lastDigestSentAt: "2026-05-01T00:00:00Z",
      appBaseUrl: "https://advocat.ee/app",
      unsubscribeToken: "tok",
    },
    T0,
  );
  assertEquals(data.newInsights.length, 5);
});

Deno.test("WD-T30 — renderDigest: contains CTA + unsubscribe", () => {
  const data = buildDigestData(
    {
      fullName: "Dmitri",
      email: "d@x.com",
      preferredLang: "en",
      activeCases: [
        { id: "c1", title: "My Case", status: "active", advice_digest: [] },
      ],
      allDeadlines: [],
      lastDigestSentAt: null,
      appBaseUrl: "https://advocat.ee/app",
      unsubscribeToken: "abc-def",
    },
    T0,
  );
  const r = renderDigest(data);
  assert(r.html.includes("Advocat"));
  assert(r.html.includes("https://advocat.ee/app"));
  assert(r.html.includes("abc-def"));
  assert(r.subject.length > 0);
  assert(r.text.includes("Advocat"));
});

Deno.test("WD-T31 — renderDigest: localises subject (ET)", () => {
  const data = buildDigestData(
    {
      fullName: "Sofia",
      email: "s@x.com",
      preferredLang: "et",
      activeCases: [
        { id: "c1", title: "Asi", status: "active", advice_digest: [] },
      ],
      allDeadlines: [],
      lastDigestSentAt: null,
      appBaseUrl: "https://advocat.ee/app",
      unsubscribeToken: "t",
    },
    T0,
  );
  const r = renderDigest(data);
  assert(r.subject.toLowerCase().includes("nädal"));
});

Deno.test("WD-T32 — renderDigest: no XSS — escapes case titles", () => {
  const data = buildDigestData(
    {
      fullName: "A",
      email: "a@b.c",
      preferredLang: "en",
      activeCases: [
        {
          id: "c1",
          title: "<script>alert(1)</script>",
          status: "active",
          advice_digest: [],
        },
      ],
      allDeadlines: [],
      lastDigestSentAt: null,
      appBaseUrl: "https://advocat.ee/app",
      unsubscribeToken: "t",
    },
    T0,
  );
  const r = renderDigest(data);
  assert(!r.html.includes("<script>alert(1)</script>"));
  assert(r.html.includes("&lt;script&gt;"));
});
