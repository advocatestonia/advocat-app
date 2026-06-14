// detectors_test.ts — regression-lock breach-detection decision logic.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  fromMassRead,
  fromStaffAccess,
  fromUsEgress,
  hourBucket,
} from "../detectors.ts";

const NOW = "2026-06-14T13:22:05.000Z";

Deno.test("BD-01 — hourBucket truncates to the hour", () => {
  assertEquals(hourBucket(NOW), "2026-06-14T13");
});

Deno.test("BD-02 — mass_read severity scales with ratio over threshold", () => {
  const out = fromMassRead(
    [
      { affected_user: "u-medium", event_count: 150 }, // 1.5x -> medium
      { affected_user: "u-high", event_count: 250 }, // 2.5x -> high
      { affected_user: "u-crit", event_count: 400 }, // 4x   -> critical
    ],
    10,
    100,
    NOW
  );
  assertEquals(
    out.find((a) => a.affectedUser === "u-medium")!.severity,
    "medium"
  );
  assertEquals(out.find((a) => a.affectedUser === "u-high")!.severity, "high");
  assertEquals(
    out.find((a) => a.affectedUser === "u-crit")!.severity,
    "critical"
  );
});

Deno.test("BD-03 — mass_read dedup key is per-user per-hour", () => {
  const [a] = fromMassRead(
    [{ affected_user: "u1", event_count: 200 }],
    10,
    100,
    NOW
  );
  assertEquals(a.dedupKey, "mass_read:u1:2026-06-14T13");
  assertEquals(a.kind, "mass_read");
  assertEquals(a.evidence.event_count, 200);
});

Deno.test("BD-04 — staff_access is high, admin_access is critical", () => {
  const out = fromStaffAccess(
    [
      { affected_user: "u1", action: "staff_read", event_count: 1 },
      { affected_user: "u2", action: "admin_access", event_count: 2 },
    ],
    60,
    NOW
  );
  assertEquals(out[0].severity, "high");
  assertEquals(out[0].kind, "staff_offsession");
  assertEquals(out[1].severity, "critical");
  // dedup includes the action so staff_read and admin_access don't collide
  assert(out[0].dedupKey.includes("staff_read"));
  assert(out[1].dedupKey.includes("admin_access"));
});

Deno.test(
  "BD-05 — us_egress fires ONLY in strict mode with a non-EU egress",
  () => {
    assertEquals(fromUsEgress(5, "off", 10, NOW).length, 0);
    assertEquals(fromUsEgress(5, "preferred", 10, NOW).length, 0);
    assertEquals(fromUsEgress(0, "strict", 10, NOW).length, 0);
    const out = fromUsEgress(3, "strict", 10, NOW);
    assertEquals(out.length, 1);
    assertEquals(out[0].severity, "critical");
    assertEquals(out[0].kind, "us_egress_when_eu");
    assertEquals(out[0].affectedUser, null);
  }
);
