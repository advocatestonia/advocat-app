# Phase 2 Pkg 4 — Case Workspace UX

**Owner:** code agent (Pkg 4)
**Status:** shipped
**Source spec:** `data/handoff_phase2_advanced.md` §«Пакет 4 — Case Workspace UX (вместо чата)»
**Replaces:** `lib/features/case_memory/screens/case_detail_screen.dart`

---

## 1. Why this exists

Today Advocat is chat-first: the case is a side-effect of a conversation,
folded into the system prompt by Pkg 1's `active_case` injection. The
moment the user owns more than one case, the chat-first frame breaks —
they need to *see the dossier*, not scroll through assistant turns.

A real lawyer works inside a **case file** (timeline, documents,
deadlines, drafts, inbox). Chat is *one tool inside that file*, not the
file itself.

Pkg 4 inverts the relationship: **the case workspace is the unit of
work**; chat becomes one tab inside it.

This is the same UX shift that got Slack from #general (everything is
a chat) to channels (everything is a workspace). Without it, even
perfect AI in chat-form feels shallow.

---

## 2. Tab structure

### 2.1 Tabs (in display order)

| # | Tab        | Content                                                                 | Empty state                      |
|---|------------|-------------------------------------------------------------------------|----------------------------------|
| 1 | Overview   | Title, jurisdiction, status, summary, last 5 timeline events, top deadline | "Add documents to build a summary." |
| 2 | Chat       | Existing chat scoped to this case (active_case auto-set on entry)       | Standard chat empty state        |
| 3 | Timeline   | Full chronological events from `user_cases.timeline` jsonb               | "No events yet."                 |
| 4 | Documents  | `case_documents` rows (Pkg 2)                                            | "No documents. Upload from Scan." |
| 5 | Deadlines  | Pkg 9 per-case list                                                      | "No upcoming deadlines."         |
| 6 | Drafts     | Persisted drafts from chat tool calls + email triage drafts              | "No drafts yet."                 |
| 7 | Inbox      | Email D6 inbox filtered to this case                                     | "No related email."              |

### 2.2 Mobile vs desktop layout — argued

**Decision: TabBar in AppBar (top tabs), responsive to bottom-of-screen tabs <600px width.**

Three patterns considered:

* **Side rail (NavigationRail).** Desktop-natural, but Advocat is a
  mobile-first app and a side rail eats horizontal space on phones (the
  primary form factor for our 17-language private-individual users in
  EE/FI/RU). Reserved for future tablet layout.
* **Bottom tabs (BottomNavigationBar inside the workspace).** Best
  thumb reach on phones, but we already have a bottom nav for the
  shell (Home / Cases / Inbox / Deadlines / Settings). A second bottom
  bar inside the workspace would compete for height with the keyboard
  on the chat tab and create two layered bottom bars when the
  workspace lives in a stacked route — UX-confusing.
* **TabBar in AppBar (chosen).** Single-line scrollable tabs in the
  AppBar (`isScrollable: true`, 7 tabs), recognisable from Gmail
  Labels, GitHub repository tabs, Linear project tabs. Plays nicely
  with the existing bottom shell — the workspace pushes a stacked
  full-screen route, the bottom shell stays out of the way.

For phones <600px we keep the same TabBar but **scroll horizontally**
rather than wrapping — this is the explicit Material 3 guidance for
content-driven tabs of variable width.

> Tablet/desktop note: when `MediaQuery.size.width >= 900` we
> *centre* the tab bar to keep it from sprawling across the page. We
> do **not** swap to a side rail in this Pkg — keeping a single
> layout reduces test surface. Side-rail can be added later behind
> the same `useWorkspace` flag without UI churn.

### 2.3 Why scrollable (and not wrap)

Wrapping a TabBar onto two rows breaks the "one tap = one switch"
intuition (the second row tabs feel like sub-tabs). Material 3 explicit
guidance: prefer scrolling over wrapping for >5 tabs.

---

## 3. Routing

```
/cases-v2/:id            → CaseWorkspaceScreen  (default tab = overview)
/cases-v2/:id?tab=chat   → CaseWorkspaceScreen  (initialTab = chat)
/cases-v2/:id?tab=timeline
/cases-v2/:id?tab=documents
/cases-v2/:id?tab=deadlines
/cases-v2/:id?tab=drafts
/cases-v2/:id?tab=inbox
```

* `?tab=` is **optional**. Unknown values fall back to `overview`.
* Switching tabs *replaces* the query param via `GoRouter.of(context).go(...)` —
  the back button reverses tab navigation (Slack-style). This is
  important on mobile where users expect Back to step *within* a
  workspace before leaving it.
* Old route `/cases-v2/:id/edit` and `/cases-v2/:id/deadlines/...`
  remain unchanged — they are sub-flows reached **from inside** the
  workspace.
* Deep-link target for D7 push and email triage carry-over: `/cases-v2/<id>?tab=inbox`.

Per-case persisted tab state lives in `SharedPreferences`
(`advocat.workspace.last_tab.<caseId>`), so reopening a case lands on
the tab the user last used. Pkg 5 (State Machine) reads this key when
deciding which tab to surface for a given `case_phase`.

---

## 4. Active-case auto-set

Entering the workspace **always** calls
`activeCaseProvider.notifier.setActiveCase(c)` in `initState`.

* This is what wires Pkg 1's `claude-proxy` injection — the chat tab
  inherits the active case for free.
* Leaving the workspace via the back button does **not** clear the
  active case (consistent with the existing chat-screen behaviour —
  the user can switch tabs to "Cases" and pick a different one).
* If the user hard-navigates to a different case workspace, the new
  workspace's `initState` overwrites the active case.

Test contract: `case_workspace_screen_test.dart` asserts that mounting
the workspace synchronously updates `activeCaseProvider`.

---

## 5. Backwards compatibility

### 5.1 Replacement, not addition

Pkg 4 **replaces** the existing
`lib/features/case_memory/screens/case_detail_screen.dart` route. The
existing top-level navigation (Cases tab → cases list → tap case →
detail) is preserved — only the rightmost screen swaps.

### 5.2 Feature flag for rollback

The router checks
`SharedPreferences.getBool('advocat.case_workspace.enabled')`. Default
is `true` (workspace enabled); a Settings toggle (one release only)
flips it back to the legacy detail screen. Removed in the next release.

| Flag value      | `/cases-v2/:id` resolves to               |
|-----------------|-------------------------------------------|
| `true` (default)| `CaseWorkspaceScreen`                     |
| `false`         | `CaseDetailScreen` (legacy, Pkg 1)        |
| `null` (first run) | `true` — workspace                     |

This is `caseWorkspaceFlagProvider` in
`lib/features/case_workspace/providers/case_workspace_provider.dart`.

### 5.3 Existing entry points still work

* `cases_list_screen.dart` already pushes `/cases-v2/<id>` — picks up
  the new route without code change.
* `_continueChat` button in legacy detail still goes to `/home` with
  the active case set — unaffected.
* Pkg 9 deadline routes (`/cases-v2/:id/deadlines/...`) live as
  sub-routes of the workspace path; routing matches them first by
  longest prefix.

---

## 6. Empty states (per tab)

Empty states are intentionally short — copy fits one line on a 320px
phone. Keys land in `app_*.arb` for EN/ET/RU/FI; other 13 locales
fallback to EN.

| Tab       | English copy                              | l10n key                       |
|-----------|-------------------------------------------|--------------------------------|
| Overview  | "Add documents to build a summary."       | `workspaceOverviewEmpty`       |
| Chat      | (uses existing chat empty state)          | —                              |
| Timeline  | "No events yet."                          | `workspaceTimelineEmpty`       |
| Documents | "No documents. Upload from Scan."         | `workspaceDocumentsEmpty`      |
| Deadlines | "No upcoming deadlines."                  | (reuses `deadlineRadarEmpty`)  |
| Drafts    | "No drafts yet."                          | `workspaceDraftsEmpty`         |
| Inbox     | "No related email."                       | `workspaceInboxEmpty`          |

---

## 7. Tab badges

Three tabs carry a small numeric badge on the right side of the tab
label. The badge is a `Container` 16px tall, rounded, brand-coloured.

| Tab       | Source provider                                         | Show when            |
|-----------|---------------------------------------------------------|----------------------|
| Inbox     | `workspaceInboxBadgeProvider(caseId)`                   | unseen CRITICAL ≥ 1 |
| Deadlines | `workspaceDeadlineBadgeProvider(caseId)`                | active ≤ 7 days ≥ 1 |
| Drafts    | `workspaceDraftsBadgeProvider(caseId)`                  | pending ≥ 1          |

Badge providers wrap the existing data sources — they don't introduce
new round-trips:

* Inbox count = `inboxProvider.threads.where(t.caseId == caseId &&
  t.severity == CRITICAL && t.seenByUserAt == null).length`.
* Deadline count = `deadlinesProvider(caseId)` filtered to active
  status with `deadlineAt <= now + 7d`.
* Drafts count = local list (Pkg 4 Drafts tab uses an in-memory
  provider seeded from chat tool result history; persistent drafts
  arrive in Pkg 7).

The `0` case renders **no** badge (so empty tabs don't look noisy).

---

## 8. State management

Riverpod, manual notifiers (matches repo convention — no `@riverpod`
codegen).

```
case_workspace_provider.dart
├── caseWorkspaceFlagProvider           Provider<bool>          (feature flag)
├── workspaceLastTabProvider             FamilyAutoDisposeProvider<WorkspaceTab, String>
├── workspaceTabSelectionProvider        StateProvider.autoDispose.family<WorkspaceTab, String>
├── workspaceInboxBadgeProvider          Provider.family<int, String>
├── workspaceDeadlineBadgeProvider       Provider.family<int, String>
└── workspaceDraftsBadgeProvider         Provider.family<int, String>
```

Tabs are an enum:

```dart
enum WorkspaceTab { overview, chat, timeline, documents, deadlines, drafts, inbox }
```

Persisted last-tab key uses `name` (overview / chat / ...) so flipping
the enum order doesn't corrupt SharedPreferences.

---

## 9. File layout

```
lib/features/case_workspace/
├── providers/
│   └── case_workspace_provider.dart
├── screens/
│   └── case_workspace_screen.dart        (TabBar host)
└── tabs/
    ├── overview_tab.dart
    ├── chat_tab.dart                     (wraps existing chat)
    ├── timeline_tab.dart
    ├── documents_tab.dart
    ├── deadlines_tab.dart                (wraps Pkg 9 list)
    ├── drafts_tab.dart
    └── inbox_tab.dart                    (wraps Email D6 with case filter)

test/features/case_workspace/
├── case_workspace_screen_test.dart       (tab nav + active-case autoset + flag)
├── overview_tab_test.dart
├── timeline_tab_test.dart
├── documents_tab_test.dart
├── deadlines_tab_test.dart
├── drafts_tab_test.dart
└── inbox_tab_test.dart
```

---

## 10. Tests (TDD)

Tests are written first, then the screen. Coverage target:

* `case_workspace_screen_test.dart` — 7 tests
  * Renders all 7 tabs.
  * `?tab=chat` activates the chat tab on mount.
  * Mounting sets the active case in `activeCaseProvider`.
  * Tapping a tab updates the URL via go_router.
  * Feature flag `false` → falls back to legacy `CaseDetailScreen`.
  * Persists last-tab to SharedPreferences when switched.
  * Reopening rehydrates last tab.

* Per-tab tests cover the **wrapper** behaviour, not the underlying
  widget (Pkg 9 Deadlines, D6 Inbox, Pkg 1 chat already have their own
  test suites). Each tab test:
  * Renders empty state when the underlying data is empty.
  * Renders content when data is present.
  * Badge providers return the expected count.

---

## 11. Coordination notes

* **Pkg 6 (Planner)** — touches `claude_service.dart` inside the chat
  layer. Pkg 4's chat_tab is a thin wrapper around `ChatScreen`, so
  Pkg 6 ships independently and the wrapper picks up the new behaviour
  for free.
* **Pkg 5 (State Machine)** — reads `workspaceLastTabProvider` to
  know which tab was opened last; can override the default tab when
  `case_phase` changes (e.g. force `Drafts` on entering phase=draft).
* **Email carry-over agent** — the inbox-side carry-over flow already
  writes `case_id` on triage rows; the inbox_tab filter is a pure
  consumer and needs no contract change.
* **Pkg 7 (Drafting Studio)** — will replace the in-memory drafts
  list with a persisted `case_drafts` table. The drafts_tab interface
  stays stable (a list of cards with title + date + body).

---

## 12. Out of scope (deferred)

* Track-changes editor inside Drafts → Pkg 7
* `case_drafts` persistence migration → Pkg 7
* Side-rail layout → after tablet UX pass
* Cross-case "you saw this in case X" suggestions → after Pkg 5
* Chat tab Locking when `case_phase=closed` → Pkg 5

---

## 13. Rollback plan

1. SharedPreferences toggle in Settings flips
   `advocat.case_workspace.enabled` to `false`. Effective on next
   route push (no app restart needed — go_router rebuilds).
2. If the toggle isn't sufficient (hard regression), revert the
   `router.dart` route swap in a hotfix; the new feature directory is
   self-contained and can stay in tree.

