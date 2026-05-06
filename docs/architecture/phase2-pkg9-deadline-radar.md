# Phase 2 Pkg 9 — Deadline Radar + Push Notifications

**Status:** design (2026-05-06). Implementer agent picks this up after Pkg 2/3/8 land.
**Owner of brief:** `data/handoff_phase2_advanced.md` (Pkg 9 section).
**Depends on:** Pkg 1 (Case Memory: `user_cases`, `case_documents`, `case-auto-patch`), Pkg 2 (PDF parser deadlines), Pkg 3 (Intake wizard), legacy `public.deadlines` (Pkg 1.A from 2026-04, today still backed by `public.cases` not `public.user_cases`).
**Migration filenames (next slots):** `20260507_09_case_deadlines.sql`, `20260507_10_deadline_notification_log.sql`, `20260507_11_deadline_extractor_rpcs.sql`.
**Out of scope:** Email Agent integration (Pkg E, separate sprint), ICS export (already shipped 2026-05-05), SMS, cross-case conflict UI v2.

---

## 1. Goal

Every active case the user owns surfaces its statutory deadlines on the home screen as a **Deadline Radar** (top-5 across all cases, color-coded), and inside each case detail screen as a per-case ordered list. Three days before the deadline a `critical` push notification fires; one day before, another; and on the morning of the deadline, a final one. 7-day and 30-day informational pushes precede them. The user persona this saves first is **Sulga-class P1 immigration**: a deportation decision served on Tuesday triggers a 30-day appeal clock under HKMS §46 (EE) or HOL §164 (FI), and a single missed Friday in week three is the difference between a winnable appeal and removal. Success = zero P1 appeals missed because of clock-blindness, measured by user self-report ("Advocat saved me from missing X") and by zero `status='missed'` rows where `priority='critical'`.

---

## 2. Statutory deadline anchors (hard-coded templates)

These live as a TypeScript constant `STATUTORY_DEADLINE_TEMPLATES` in `supabase/functions/_shared/deadline_anchors.ts`, mirrored in Dart at `lib/features/case_memory/data/statutory_anchors.dart`. They are **templates** — applied by the extractor when it sees a matching `doc_type` + `jurisdiction` pair, never as automatic deadlines without a triggering document.

| Anchor key | Jurisdiction | Statute | Trigger document type | Days | Counting | Service-clock rule | UI label (ET/FI/EN/RU) |
|---|---|---|---|---|---|---|---|
| `ee_hkms_46_kaebus` | EE | HKMS §46 | `court_decision` (haldusotsus) | 30 | calendar | HMS §27 e-mail = 5th calendar day | Kaebus halduskohtule / — / Appeal to Administrative Court / Жалоба в адм. суд |
| `ee_hms_75_vaie` | EE | HMS §75 | `admin_decision` | 30 | calendar | HMS §27 (e-mail = 5p), §25 (paper = §25 lg 3) | Vaie / — / Administrative complaint / Возражение |
| `ee_hms_27_e_service` | EE | HMS §27 | (modifier, not a deadline itself) | +5 | calendar | electronic service clock | — |
| `fi_hol_2019_808_khoa` | FI | Hallintolainkäyttölaki + HOL §164 | `court_decision` (KHO/HAO päätös) | 30 | calendar | HL §59 (regular email +3 working days), §60 (turvaviesti = 7th calendar day) | — / Valitus KHO:hon / Appeal to Supreme Admin Court / Апелляция KHO |
| `fi_hl_49b_oikaisu` | FI | Hallintolaki §49b | `admin_decision` | 30 | calendar | HL §59/§60 service-clock | — / Oikaisuvaatimus / Administrative reclamation / Заявление об исправлении |
| `fi_hl_59_regular_email_service` | FI | HL §59 | (modifier) | +3 working days | working | regular email service clock | — |
| `fi_hl_60_turvaviesti_service` | FI | HL §60 | (modifier) | 7 calendar days from sending | calendar | turvaviesti / suojattu sähköposti pickup clock | — |
| `fi_posti_omniva_pickup` | FI/EE | Posti/Omniva | (modifier on physical service) | 14 | calendar | warehouse pickup window | — |
| `eu_echr_protocol_15` | strasbourg | ECHR Protocol 15 | `final_domestic_judgment` | 4 calendar months | strict calendar months, **no weekend extension, no holiday extension** | from final domestic judgment date | — / — / ECHR application / Жалоба в ЕСПЧ |

**Modifiers** (`fi_hl_59_*`, `fi_hl_60_*`, `ee_hms_27_e_service`, `posti_pickup`) are not deadlines on their own — the extractor combines them with the corresponding base deadline. Example: a Migri turvaviesti notification of a deportation decision served on 2026-05-06 generates a `fi_hol_2019_808_khoa` deadline of `2026-05-06 + 7d (HL §60 pickup) + 30d` = `2026-06-12`, with `holiday_shifted_at` set if 2026-06-12 falls on a Finnish holiday or weekend.

---

## 3. Calendar / holiday awareness

Reuse the FI/EE holiday lists already encoded for OPERATOR_PROMPT Rule 28 (consilium 2026-04-24). Holidays live as a static array in `supabase/functions/_shared/holidays_fi_ee.ts` and a mirrored Dart const at `lib/features/case_memory/data/holidays_fi_ee.dart`. The arrays cover **2026 and 2027**; a CI test asserts the current year + next year are populated, fails the build if drift makes the list stale.

**Counting algorithm (`computeAbsoluteDeadline(serviceDate, anchor)`):**

1. Apply service-clock modifier first (e.g. HL §60: `serviceDate + 7d`; HMS §27: `serviceDate + 5d`; HL §59: `serviceDate + 3 working days`).
2. Add the statutory window: 30 calendar days for kaebus/valitus/oikaisuvaatimus/vaie; **4 calendar months for ECHR** (use `addMonths` not `addDays`).
3. Holiday-shift the result forward to the next non-weekend, non-holiday day **except for ECHR Protocol 15**, which is strict calendar (do not shift). Encode this as a per-anchor `holidayShiftPolicy: 'next_business_day' | 'strict_calendar'`.
4. Stamp `service_basis text` (e.g. `"HL §60 turvaviesti — 7th calendar day from sending"`) so the UI tooltip can explain why the clock starts when it does.
5. Stamp `holiday_shifted: bool` so the UI can show a "(moved from Sat → Mon)" annotation.

The function lives in `_shared/deadline_anchors.ts` and is the **single source of truth** — both the server-side extractor and any client-side preview UI must import from there. No duplicate JS-on-server vs Dart-on-client implementations: Dart imports a precomputed JSON of anchor metadata; the actual computation only runs server-side.

---

## 4. Schema changes

### Decision: NEW table `case_deadlines`, NOT in-place jsonb extension.

**Why:** `user_cases.key_dates jsonb` (Pkg 1) holds AI-extracted *historical events* and unstructured key dates — append-only with composite-key dedupe (`canonicalKey` in `case_patch_prompt.ts` lines 344–379). It is intentionally a low-structure dumping ground for the Haiku extractor. Putting Deadline Radar on that array means:

- Querying `WHERE deadline_at < now() + 7d` requires unnesting jsonb in every cron tick (slow, no index help on jsonb without a generated column);
- `status` (active/completed/missed) becomes a property of an array element, no per-row primary key, no clean `UPDATE ... WHERE id =` for "mark completed";
- pg_cron + `notification_log` cannot foreign-key to a jsonb element, so idempotency is hand-rolled string math;
- RLS on jsonb element ownership is impossible — only the row-level `auth.uid() = user_id` exists, but completed-by-user-X-on-device-Y semantics need a real row.

The legacy `public.deadlines` table (001_complete_schema.sql line 182, FK to `public.cases`) **cannot be reused** because Pkg 1 deliberately moved cases to `public.user_cases` and the FK is incompatible. We follow the same path Pkg 1 took with `chat_messages.case_id`: leave the legacy table in place for the legacy `cases` table, build a new sibling table for `user_cases`. Naming `case_deadlines` (not `user_case_deadlines`) avoids the awkward double-prefix while matching `case_documents` / `case_chat_sessions` from Pkg 1.

**One-time data path for the legacy table:** out of scope for Pkg 9. The legacy `public.deadlines` rows belong to legacy `public.cases`, none of which are tied to a real Phase-2 user case. The owner accepts that legacy deadlines will not migrate; legacy table stays for historical readability and may be dropped in a future cleanup migration.

### Migration `20260507_09_case_deadlines.sql`

```sql
-- =====================================================================
-- Phase 2 Pkg 9 — Deadline Radar
-- Sibling of case_documents / case_chat_sessions (Pkg 1.A 20260506).
-- New table because jsonb-on-user_cases lacks per-row primary key, RLS
-- granularity, and pg_cron foreign-key targets the radar needs.
-- =====================================================================

create extension if not exists "uuid-ossp";

-- Statuses: active = clock running; completed = user marked done;
-- missed = clock expired without completion; archived = case archived.
do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_deadline_status') then
    create type case_deadline_status as enum ('active','completed','missed','archived');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_deadline_priority') then
    create type case_deadline_priority as enum ('critical','high','medium','low');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'case_deadline_source') then
    create type case_deadline_source as enum
      ('pdf','intake','manual','email','haiku_extract','statutory_template');
  end if;
end $$;

create table if not exists public.case_deadlines (
    id                  uuid primary key default gen_random_uuid(),
    case_id             uuid not null references public.user_cases(id) on delete cascade,
    user_id             uuid not null references auth.users(id) on delete cascade,
    title               text not null,
    description         text,
    statute_basis       text,                    -- 'HKMS §46' | 'HOL §164' | 'ECHR Protocol 15'
    anchor_key          text,                    -- 'ee_hkms_46_kaebus' from STATUTORY_DEADLINE_TEMPLATES
    service_date        date,                    -- raw service date, NULL if unknown
    service_basis       text,                    -- 'HL §60 turvaviesti — 7th calendar day from sending'
    deadline_at         timestamptz not null,    -- absolute, holiday-shifted, in user TZ-aware UTC
    holiday_shifted     boolean not null default false,
    holiday_shift_note  text,                    -- 'moved from Sat 2026-06-13 → Mon 2026-06-15'
    source              case_deadline_source not null default 'manual',
    source_doc_id       uuid references public.case_documents(id) on delete set null,
    status              case_deadline_status not null default 'active',
    priority            case_deadline_priority not null default 'high',
    completed_at        timestamptz,
    completed_note      text,                    -- user free-text on completion
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

create index if not exists case_deadlines_user_active_idx
    on public.case_deadlines (user_id, deadline_at)
    where status = 'active';
create index if not exists case_deadlines_case_idx
    on public.case_deadlines (case_id);
create index if not exists case_deadlines_status_idx
    on public.case_deadlines (status);
-- partial index for cron scan: only active, future-or-recent rows.
create index if not exists case_deadlines_cron_scan_idx
    on public.case_deadlines (deadline_at)
    where status = 'active';

create or replace function public.touch_case_deadlines_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end;
$$;
drop trigger if exists case_deadlines_updated_at on public.case_deadlines;
create trigger case_deadlines_updated_at
    before update on public.case_deadlines
    for each row execute function public.touch_case_deadlines_updated_at();

alter table public.case_deadlines enable row level security;
drop policy if exists "own case deadlines" on public.case_deadlines;
create policy "own case deadlines" on public.case_deadlines
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Helper RPC: top-N upcoming actives for radar widget.
-- security invoker → RLS confines results to the calling user.
create or replace function public.active_deadlines(p_limit int default 10)
returns table (
    id uuid, case_id uuid, case_title text, title text, statute_basis text,
    deadline_at timestamptz, priority case_deadline_priority,
    delta_days int, holiday_shifted boolean, source case_deadline_source
)
language sql stable security invoker
set search_path = public
as $$
    select
        d.id, d.case_id, c.title as case_title, d.title, d.statute_basis,
        d.deadline_at, d.priority,
        greatest(0, ceil(extract(epoch from (d.deadline_at - now()))/86400))::int as delta_days,
        d.holiday_shifted, d.source
    from public.case_deadlines d
    join public.user_cases c on c.id = d.case_id
    where d.status = 'active'
      and c.status = 'active'
    order by d.deadline_at asc
    limit greatest(1, least(p_limit, 50))
$$;

-- Per-case list (for case detail screen).
create or replace function public.case_deadlines_for(p_case_id uuid)
returns setof public.case_deadlines
language sql stable security invoker
set search_path = public
as $$
    select * from public.case_deadlines
    where case_id = p_case_id
    order by
      case status when 'active' then 0 when 'missed' then 1 when 'completed' then 2 else 3 end,
      deadline_at asc
$$;

notify pgrst, 'reload schema';
```

### Migration `20260507_10_deadline_notification_log.sql`

```sql
-- Idempotency for the cron pusher: each (deadline_id, threshold) fires
-- exactly once. service_role-only insert; user can read their own log
-- (so the UI can show "we notified you 3 days ago at 14:02").
create table if not exists public.deadline_notification_log (
    id           uuid primary key default gen_random_uuid(),
    deadline_id  uuid not null references public.case_deadlines(id) on delete cascade,
    user_id      uuid not null references auth.users(id) on delete cascade,
    threshold    text not null check (threshold in ('30d','7d','3d','1d','morning_of')),
    channel      text not null check (channel in ('push','email','in_app')),
    fired_at     timestamptz not null default now(),
    delivered    boolean not null default false,
    delivery_error text,
    unique (deadline_id, threshold, channel)
);

create index if not exists deadline_notification_log_deadline_idx
    on public.deadline_notification_log (deadline_id);
create index if not exists deadline_notification_log_user_idx
    on public.deadline_notification_log (user_id);

alter table public.deadline_notification_log enable row level security;
drop policy if exists "own notification log" on public.deadline_notification_log;
create policy "own notification log" on public.deadline_notification_log
    for select using (auth.uid() = user_id);
-- inserts/updates only via service-role (cron). No insert/update/delete policies.

notify pgrst, 'reload schema';
```

### Migration `20260507_11_deadline_extractor_rpcs.sql`

Helper `apply_deadline_extraction(p_case_id uuid, p_doc_id uuid, p_extracted jsonb)` accepts the PDF parser's `deadlines: [{date, what, statute}]` shape (helpers.ts line 112) and the intake wizard's structured dates, applies `STATUTORY_DEADLINE_TEMPLATES` matching, computes the absolute deadline server-side via a Postgres function `pg_compute_deadline(anchor_key, service_date)` that mirrors the TS logic, dedupes against existing rows, returns the new `case_deadlines.id` array. `security definer`, `set search_path = public`, `auth.uid() is null` rejection. Pure SQL where possible; Postgres holiday lookup uses a static `fi_ee_holidays` materialized view loaded by the migration itself (idempotent insert from an array literal).

---

## 5. Background extractor (server-side)

### Decision: NEW edge function `deadline-extractor`, called from three sites; do **not** extend `case-auto-patch`.

**Why not extend case-auto-patch:**
- case-auto-patch is per-chat-turn. Most assistant turns do not introduce a deadline; running deadline classification on every turn wastes Haiku tokens and adds latency to the silent-write path the chat client never awaits.
- case-auto-patch already extracts `key_dates_add` (case_patch_prompt.ts line 49) — a generic dated-event list. Re-using that as the deadline source means treating *every* `key_dates` entry as a candidate deadline, which conflates "date I was served the päätös" (informational) with "date I must file by" (actionable).
- case-auto-patch runs on the user's JWT via `loadCaseAsUser` (case-auto-patch line 217). Adding statutory-template lookup against a service-role-only `apply_deadline_extraction` would require splitting into a chained call anyway.

### Function `deadline-extractor`

**Three trigger sites:**

1. **After `pdf-parser` succeeds** — the parser already emits `extracted.deadlines: [{date, what, statute}]` (helpers.ts). Add a final step in `pdf-parser/index.ts` that POSTs to `deadline-extractor` with `{case_id, doc_id, deadlines: extracted.deadlines, doc_type, jurisdiction}` after the `case_documents` row is written. Best-effort: failure does not fail the parse.

2. **After `intake-wizard-finish`** (Pkg 3) — when the wizard saves a structured date as e.g. `service_date_of_decision`, the wizard endpoint POSTs to `deadline-extractor` with `{case_id, intake_payload, jurisdiction}`. The extractor maps wizard fields to anchor keys (e.g. `service_date_of_decision` + `case_type=immigration` + `jurisdiction=FI` → `fi_hol_2019_808_khoa`).

3. **Post-case-auto-patch handoff** — after case-auto-patch returns a non-empty patch with `key_dates_add` items containing the keyword "deadline" / "tähtaeg" / "kaebetähtaeg" / "valitusaika" / "срок обжалования", the chat client (or a Postgres `after update` trigger on `user_cases.key_dates`) fires `deadline-extractor` with `{case_id, candidate_dates: [...], jurisdiction}`. The extractor uses Sonnet (NOT Haiku — junior model misses jurisdictional nuance per consilium 2026-05) to classify each candidate as either a deadline (with anchor) or just a calendar event. Sonnet returns strict JSON: `[{date, anchor_key, statute_basis, priority, confidence}]`. Confidence below 0.7 → `priority='medium'` and a UI flag "AI-extracted, please verify".

**Function contract:**

```
POST /functions/v1/deadline-extractor
Headers: Authorization: Bearer <user JWT> (or x-cron-secret for site 1 invoked from pdf-parser via service-role)
Body:
  {
    case_id: uuid,
    source: 'pdf' | 'intake' | 'haiku_extract',
    payload: { ... source-specific ... },
    jurisdiction?: 'EE' | 'FI' | 'EU'
  }
Response 200: { created: number, updated: number, deadlines: [{id, deadline_at, anchor_key}] }
Response 4xx/5xx: error envelope mirrored from case-auto-patch conventions.
```

**Server-side dedupe rule:** `(case_id, anchor_key, deadline_at::date)` is the natural key. Two extractions of the same kaebus deadline from the päätös PDF and from the intake wizard must NOT create two rows. The function `apply_deadline_extraction` upserts on this composite.

**Sonnet system prompt** (lives in `_shared/deadline_extractor_prompt.ts`, mirrors the Pkg 1 case-patch identity-marker pattern, whitelisted by `system_prompt_guard.ts`):

> You are a deadline-classifier for the Advocat app. Given candidate dates and a jurisdiction, output strict JSON listing only the dates that represent statutory legal deadlines (appeal windows, hearing dates, response-by dates). For each, return the matching `anchor_key` from STATUTORY_DEADLINE_TEMPLATES, the citing statute, your confidence (0–1), and the suggested priority. Reject calendar events (case opened, document received) and out-of-jurisdiction anchors. Output JSON only, no preamble.

---

## 6. Notification scheduler

### pg_cron job: `deadline_radar_tick`

Runs **every 15 minutes**. Why not hourly: at the `1d` and `morning_of` thresholds, a 1-hour resolution means a user could get the "1 day left" push at 23:59 the day before, then "morning of" 8 hours later — confusing. 15 min lets us pin the morning push to 08:00 user-local-time within a tight window.

Why not 5 min: scanning `case_deadlines WHERE status='active'` 12× more often does nothing useful — thresholds don't move that fast — and burns service-role compute.

```sql
select cron.schedule(
  'deadline-radar-tick',
  '*/15 * * * *',
  $$ select net.http_post(
       url := current_setting('app.deadline_radar_endpoint'),
       headers := jsonb_build_object(
         'Content-Type', 'application/json',
         'x-cron-secret', current_setting('app.cron_secret')
       ),
       body := '{}'
     ); $$
);
```

(Endpoint URL + cron secret stored as Postgres GUCs, set at deploy time. Pattern matches existing `agent-intentions-cron`.)

### Edge function `deadline-radar-tick`

`x-cron-secret` gated (`deadline-reminder/auth_gate.ts` pattern, lessons learned from FIX-5). Service-role client.

**Per tick:**

1. `select * from case_deadlines where status='active' and deadline_at > now() - '24 hours' and deadline_at < now() + '35 days'` — bound the scan, ignore long-distant deadlines, ignore stale missed ones (a separate sweep below handles `missed` transitions).
2. For each row, compute `delta_seconds = deadline_at - now()`.
3. Compute the threshold the row currently falls into: `30d` if 27d < delta ≤ 30d; `7d` if 5d < delta ≤ 7d; `3d` if 36h < delta ≤ 72h; `1d` if 8h < delta ≤ 36h; `morning_of` if today's date in user TZ matches `deadline_at::date`. Note the **threshold windows are bounded ranges**, not single instants — guarantees we don't miss a tick if the cron drifts. (Lessons from email-agent retry idempotency: bounded ranges + idempotency log = correct pushes even with cron drift.)
4. For each threshold a row falls into, attempt to insert into `deadline_notification_log (deadline_id, threshold, channel)` — the unique constraint guarantees we never re-fire. Insert per channel (`push`, `email` for critical only, `in_app` always).
5. After successful insert, call the actual delivery: FCM via existing `notification_service.dart`'s topic `case_<case_id>` (the user has already subscribed via `subscribeToCaseUpdates` in Pkg 1.D). For email, reuse `send-email`. For in-app, insert into the existing `notifications` table (legacy, used by `deadline-reminder`, kept for backward compat).
6. Separate sweep: `update case_deadlines set status='missed' where status='active' and deadline_at < now() - '6 hours'` — a 6-hour grace because timezone drift between user-local and server clocks can let a "morning of" push fire after midnight.

**Quiet hours:** 21:00–08:00 in **user TZ**. Stored as `users.tz` (already exists from Phase 1) or default to `Europe/Helsinki`. Non-critical thresholds (`30d`, `7d`) defer to next 08:00 by inserting a `deferred_until` row in a small `deadline_push_queue` table (NEW, optional — could be added in `20260507_12_*` if cron logic gets messy). Critical thresholds (`3d`, `1d`, `morning_of`) bypass quiet hours — a missed appeal is worse than a wakeup ping.

**Permission denied → graceful degrade:** if FCM returns "subscription not found" / "permission revoked", mark `delivery_error='no_fcm_subscription'` in the log and fall through to the in-app notification. If the user had configured an email channel, fall through to email for `priority='critical'` only.

### Push channel inventory

- **FCM** — already wired in `lib/services/notification_service.dart`, type `'deadline_reminder'` already routed (line 78). No new dependency.
- **In-app banner** — existing `notifications` table from legacy. The Flutter `chat_screen` and `cases_list_screen` already poll/subscribe.
- **Email fallback** — existing `send-email` edge function, ElevenLabs/Brevo path. Critical thresholds only.

---

## 7. Flutter UI

### Files (new)

- `lib/features/case_memory/widgets/deadline_radar_widget.dart` — top-5 deadlines across all active cases, lives on home screen and cases-list screen.
- `lib/features/case_memory/widgets/deadline_card.dart` — single-deadline rendering primitive: title, statute basis, days-left chip, priority color, source icon, action menu (mark complete / snooze / edit).
- `lib/features/case_memory/widgets/deadline_banner.dart` — slot-in widget for `case_detail_screen.dart`: red banner if any active deadline ≤ 3d, persistent until acknowledged for the session.
- `lib/features/case_memory/screens/case_deadlines_screen.dart` — full per-case list, reachable from case detail.
- `lib/features/case_memory/screens/deadline_edit_screen.dart` — manual create/edit form, with anchor-template picker (FI/EE/ECHR), service-date input, computed-deadline preview.

### Files (modified)

- `lib/features/case_memory/screens/cases_list_screen.dart` — slot `DeadlineRadarWidget` above the list.
- `lib/features/home/screens/home_screen.dart` — slot `DeadlineRadarWidget` near the chat CTA.
- `lib/features/case_memory/screens/case_detail_screen.dart` — slot `DeadlineBanner` at top, link to `CaseDeadlinesScreen`.
- `lib/features/chat/screens/chat_screen.dart` — slot `DeadlineBanner` if active case has critical deadline, dismiss-for-session.

### Color coding (Theme.of)

- `priority='critical'` AND `delta_days <= 3`: red 700 background, white text, white pulse.
- `priority='critical'` AND `delta_days <= 7`: red 500 background.
- `priority='high'` AND `delta_days <= 14`: amber 700.
- Else: theme `colorScheme.surfaceContainerHigh`.

Reuse existing app theme tokens; do not introduce new color constants.

### l10n

Add 8 keys to `app_*.arb` (17 locales): `deadlineRadarTitle`, `deadlineCardDaysLeft`, `deadlineCardOverdue`, `deadlineCardMarkComplete`, `deadlineCardSnooze`, `deadlineCardSourceLabel{Pdf,Intake,Manual,HaikuExtract,StatutoryTemplate}`, `deadlineBannerCritical`, `deadlinePermissionAskTitle`, `deadlinePermissionAskBody`. Use `app_localizations` codegen, do not hand-edit the `.dart` files.

---

## 8. Riverpod state

### `deadlinesProvider(caseId)` — `FutureProvider.family<List<CaseDeadline>, String>`

Wraps `supabase.rpc('case_deadlines_for', {p_case_id: caseId})`. Auto-invalidated by:

- `caseAutoPatchProvider` listener: when case-auto-patch returns `fields_changed` containing `key_dates`, invalidate this provider for `caseId`.
- Realtime subscription on `case_deadlines` filtered to `case_id=eq.{caseId}` (Supabase Realtime channel). Pattern matches `caseDocumentsProvider` from Pkg 1.D.

### `globalDeadlinesProvider` — `FutureProvider<List<DeadlineRadarRow>>`

Wraps `supabase.rpc('active_deadlines', {p_limit: 10})`. Used by `DeadlineRadarWidget`. Auto-invalidated on:

- Any `deadlinesProvider` invalidation (cascade via ref.listen).
- `deadlineNotificationLogProvider` ticking — i.e. a fresh push fires, the global radar should re-pull to surface the freshest delta-days.
- App-foreground transition (`AppLifecycleListener.onResume`).

### `deadlineMutationsProvider` — `Notifier`

Methods: `markComplete(deadlineId, note?)`, `snooze(deadlineId, until)`, `archive(deadlineId)`, `createManual(...)`, `editManual(...)`. Each invalidates `deadlinesProvider(caseId)` + `globalDeadlinesProvider`.

---

## 9. Notification permission flow

### When to ask

NOT on app launch (anti-pattern, low conversion, training the user to deny). Ask **inline** the first time:

- The user opens a `case_detail_screen` that has any `case_deadlines` row, OR
- The user dismisses the first `DeadlineBanner`.

A `_promptedDeadlinePermissionV1` SharedPreferences flag prevents re-asking. If denied, a "🔔 Enable deadline reminders" button stays in `settings_screen` for the user to opt in later.

### Ask copy (l10n)

> "Want a reminder before [deadline]? We'll ping you 7, 3, and 1 day before, plus the morning of. We never use this for marketing."

### Settings toggles

- Master push toggle.
- Per-channel: push / email / in-app.
- Quiet hours start/end (default 21:00 / 08:00 user TZ).
- "Critical bypass quiet hours" (default ON, prominent).

### Graceful degrade

If FCM permission denied or revoked: server-side `deadline-radar-tick` detects missing FCM subscription, falls through to in-app + (for `critical`) email. The user still gets the safety net — just slower. No UI scolding.

---

## 10. Test plan (top 8 — enumerate, do not implement here)

1. **Holiday-shift correctness FI:** kaebetähtaeg landing on Suvistepühade reede shifts to next Mon; assert `holiday_shifted=true`, note populated.
2. **Holiday-shift correctness EE:** vaie landing on Võidupüha shifts to next business day.
3. **ECHR no-weekend-shift:** Strasbourg deadline on a Saturday stays Saturday (`holiday_shift_policy='strict_calendar'`); regression-pin against issue from old `lib/services/legal_deadline_database.dart` notes.
4. **Threshold debounce:** `deadline_notification_log` unique constraint blocks duplicate push when cron runs back-to-back due to drift; only one row per `(deadline_id, threshold, channel)`.
5. **RLS owner-only:** anon JWT cannot select `case_deadlines`; another user's JWT returns 0 rows; service-role can write.
6. **Service-date-unknown handling:** intake wizard saves a deadline candidate with `service_date=null` → extractor returns `created=0` and writes a `case_deadlines` row only if the document carries an explicit absolute date; assert no half-baked deadlines appear.
7. **Completed deadline does not re-fire:** mark complete, run `deadline-radar-tick` → log untouched, no push.
8. **Quiet hours respect:** non-critical 7d push at 22:00 user-TZ defers to 08:00; critical 1d push at 22:00 fires anyway; assert by faking `now()` in the test harness.

(Also: Sonnet extractor confidence-threshold gating, missing FCM permission graceful degrade, Haiku's `key_dates` re-extraction does not reopen completed deadlines.)

---

## 11. Risks (top 5)

1. **False-positive deadlines from Haiku/Sonnet misextraction.** A Sonnet pass at confidence < 0.7 marks the deadline `priority='medium'` with a UI "verify this" badge. A separate `deadline_review_queue` (out of scope for v1) could batch low-confidence rows for owner review. Mitigation in v1: never auto-create a `priority='critical'` deadline from `source='haiku_extract'`; require `source IN ('pdf','intake','manual')` for critical priority. Encode as DB check constraint.

2. **Push permission denied → user silently misses critical deadline.** Server-side fallback to in-app + email for critical, AND the radar widget itself is the primary defense (visible every time the user opens the app). The push is a *bonus* layer, not the only one.

3. **pg_cron drift.** 15-min ticks with bounded threshold ranges (rule §6.3) and the `deadline_notification_log` unique constraint guarantee at-least-once and at-most-once delivery per threshold even when the cron is 30 min late or fires twice in the same minute.

4. **Multi-track case with conflicting deadlines on same day.** E.g. Sulga's Линия А and Линия Б may both have a kaebetähtaeg on the same Monday. UI groups deadlines by day in the per-case list (header "Mon 2026-06-15 — 2 deadlines") to prevent visual confusion. Cross-case grouping in the global radar is v2.

5. **User completes a deadline manually but Haiku re-extracts it on next chat turn.** Server-side: `apply_deadline_extraction` upsert dedupe is keyed on `(case_id, anchor_key, deadline_at::date)`. If a row with `status='completed'` matches, we keep the completed status (do not reopen). Test #7 covers this.

---

## 12. Out of scope (explicit non-goals for Pkg 9)

- **Email Agent** integration (Pkg E, separate sprint) — when it lands, it adds `source='email'` rows via the same `apply_deadline_extraction` RPC. No schema change needed.
- **ICS calendar export** — already shipped 2026-05-05. Pkg 9 wires the existing `ics_export_service.dart` to read from `case_deadlines` instead of (or in addition to) the legacy `deadlines` table — single-line change, do not re-implement.
- **SMS notifications** — premium tier, future sprint.
- **Cross-case deadline conflict UI v2** — when the same authority has overlapping deadlines across two of the user's cases. v1 lists them separately.
- **Editing the holiday list per-case** — e.g. user is in court Mon, wants to mark personal days. v2.
- **Deadline templates auto-applied without source document** — anti-pattern, encourages phantom deadlines.

---

## Hard-constraint compliance checklist

- [x] Migration `_NN_` rule respected: `20260507_09`, `_10`, `_11` — next slots after Pkg 2's `_08`.
- [x] All RPCs `security definer` (or `security invoker` where RLS is the gate); explicit `set search_path = public`.
- [x] `auth.uid() is null` check on `security definer` writes (encoded in `apply_deadline_extraction`).
- [x] No new external dependencies — FCM via existing `firebase_messaging` (already in pubspec), no new npm/deno modules.
- [x] Pre-commit / pre-push testable — the deadline computation function is pure, the extractor is JWT-gated, the cron is cron-secret-gated. Each path has a corresponding unit/integration test slot in §10.
- [x] App-only — zero touches to `business/`.
- [x] Identity-marker on Sonnet system prompt for `system_prompt_guard.ts` whitelist.
- [x] PII discipline: response bodies from `deadline-radar-tick` are counts only (lessons from FIX-5), never echo titles/dates.
- [x] Anon-JWT-bypass guard: `auth_gate.ts` pattern reused (lessons from `lesson_anon_jwt_bypass.md`).

---

## Implementation sequencing (suggested, owner decides)

1. Migration `_09` + `_10` + `_11` + `_shared/deadline_anchors.ts` + `_shared/holidays_fi_ee.ts` + unit tests for `computeAbsoluteDeadline`.
2. `deadline-extractor` edge function + tests; wire from `pdf-parser` first (fewest moving parts), then intake wizard, then case-auto-patch.
3. `deadline-radar-tick` edge function + pg_cron schedule + idempotency tests.
4. Flutter widgets (radar, banner, card) + Riverpod providers; ship behind a feature flag `pkg9_deadline_radar` for canary.
5. Notification permission flow + settings toggles.
6. ICS export wiring to `case_deadlines`.
7. Eval suite test #6 from Pkg 8 covers "identified deadline if exists" — verify Pkg 9 raises that score.
