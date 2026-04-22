-- =====================================================================
-- OMEGA-BULLETPROOF BP-3: event_kind column for app_errors
-- =====================================================================
-- Purpose
--   The launch/wave1 Sentry-lite sink stores errors as a flat append-only
--   stream. BP-3 needs to distinguish critical operational categories
--   (AI failures vs. billing failures vs. security violations) without
--   adding a second table.
--
-- Design decisions
--   * Optional column with a text check — enum-like without pg enum.
--   * Default `error` preserves backwards compatibility: any insert from
--     the existing Flutter telemetry sink continues to work unmodified.
--   * Alerting rules in `config/monitoring/alert_rules.yaml` key off
--     this column.
-- =====================================================================

alter table public.app_errors
  add column if not exists event_kind text
    not null
    default 'error'
    check (event_kind in (
      'error',          -- generic client-side exception (default)
      'ai_failure',     -- Claude-proxy returned error / empty / timeout
      'stripe_failure', -- webhook parse fail, sub transition rejected
      'cron_failure',   -- deadline-reminder / scheduled task crashed
      'rls_violation',  -- client tried to write a row auth.uid() doesn't own
      'cap_hit',        -- founder cap or anon rate-limit tripped
      'cost_alert'      -- daily Claude spend above threshold
    ));

create index if not exists idx_app_errors_kind
  on public.app_errors (event_kind, occurred_at desc);

comment on column public.app_errors.event_kind is
  'BP-3: category for alerting. See config/monitoring/alert_rules.yaml.';
