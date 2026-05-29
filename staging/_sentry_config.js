/* ============================================================================
 * Advocat — Sentry DSN injection shim
 * ============================================================================
 *
 * Created: 2026-05-29
 * Why a separate file: keeps the DSN out of the HTML source tree. The
 * placeholders below are rewritten by scripts/canary-deploy.sh at deploy
 * time with the real values from the SENTRY_DSN env var + the current
 * git short-SHA. Local dev / preview builds keep the placeholder strings,
 * which makes _sentry_init.js exit early (graceful degradation — no
 * Sentry.init() call, no network traffic to ingest.sentry.io).
 *
 * Owner action to activate:
 *   1. Create project at sentry.io (organization: advocat)
 *   2. Set env var:  export SENTRY_DSN="https://<key>@<org>.ingest.sentry.io/<project>"
 *   3. Re-run scripts/canary-deploy.sh (which sed-substitutes both
 *      placeholders into build/web/_sentry_config.js post-rsync, before
 *      `git push github HEAD:gh-pages`).
 *
 * If SENTRY_DSN is unset at deploy time, canary-deploy.sh leaves the
 * placeholders intact and Sentry stays dormant — the landing keeps
 * working exactly as before.
 *
 * NEVER commit a real DSN into this file. The DSN identifies the
 * project but is also the write-key for ingest, and a leaked DSN
 * allows anyone to flood the project with events (cost + noise).
 * ============================================================================ */
window.__SENTRY_DSN__ = '__SENTRY_DSN_PLACEHOLDER__';
window.__APP_VERSION__ = '__APP_VERSION_PLACEHOLDER__';
