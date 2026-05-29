/* ============================================================================
 * Advocat — Sentry browser SDK initialiser (PII-scrubbed)
 * ============================================================================
 *
 * Created: 2026-05-29
 * Loaded by: index.html, for-firms.html, demo.html (all `defer`)
 * Depends on: _sentry_config.js (sets window.__SENTRY_DSN__) + the Sentry
 *             CDN bundle `bundle.tracing.replay.min.js` (pinned 8.42.0,
 *             SHA384-verified via SRI on the <script> tag).
 *
 * Safety contract — what Sentry MAY see:
 *   - JS errors + stack traces
 *   - Web Vitals (LCP, INP, CLS) via browserTracingIntegration
 *   - Sampled session replay ONLY on error (replaysOnErrorSampleRate 0.1),
 *     with maskAllText + blockAllMedia + maskAllInputs (PII-safe by default)
 *
 * What Sentry MUST NOT see:
 *   - User emails, names, phones, case numbers, draft IDs (scrubUrl + scrubPii)
 *   - Cookies or request bodies (deleted from every event)
 *   - Auth / login / token fetches (beforeBreadcrumb drops the breadcrumb)
 *   - Anything resembling an email address or a long alphanumeric case ID
 *     in the error message itself (looksLikePii → return null → drop event)
 *
 * Cost guard: replaysSessionSampleRate = 0 (no idle replays — too expensive).
 *             tracesSampleRate = 0.1 (10% of transactions). Session replay
 *             only fires on errors, and even then only 10% of them.
 *
 * Graceful degradation: if the CDN bundle didn't load (Sentry undefined),
 * or if SENTRY_DSN is still the placeholder, this file exits silently.
 * ============================================================================ */
(function () {
  'use strict';

  // ---- Helpers (defined first so init can reference them) ----------------

  function looksLikePii(s) {
    if (!s || typeof s !== 'string') return false;
    // Email pattern (covers all common forms incl. RFC-loose).
    if (/@[\w.-]+\.\w{2,}/.test(s)) return true;
    // Case-number / passport-style: 2+ caps then 6+ digits.
    if (/\b[A-Z]{2}\d{6,}\b/.test(s)) return true;
    // Finnish HETU (DDMMYY[-+A]NNNX).
    if (/\b\d{6}[-+A]\d{3}[0-9A-Z]\b/.test(s)) return true;
    // Estonian isikukood (G YYMMDD NNN C — 11 digits, starts 3-6).
    if (/\b[3-6]\d{10}\b/.test(s)) return true;
    return false;
  }

  function scrubUrl(url) {
    try {
      var u = new URL(url, window.location.origin);
      var PII_PARAMS = [
        'email', 'e-mail', 'name', 'firstname', 'lastname',
        'phone', 'tel', 'mobile',
        'case_id', 'caseid', 'case',
        'draft_id', 'draftid', 'draft',
        'token', 'access_token', 'refresh_token', 'id_token',
        'code',           // OAuth authorization codes
        'state',          // OAuth state (often holds session correlations)
        'session',
        'jwt',
        'hetu',           // Finnish personal code
        'isikukood',      // Estonian personal code
      ];
      for (var i = 0; i < PII_PARAMS.length; i++) {
        if (u.searchParams.has(PII_PARAMS[i])) {
          u.searchParams.set(PII_PARAMS[i], '[REDACTED]');
        }
      }
      return u.toString();
    } catch (_) {
      return url;
    }
  }

  function scrubPii(event) {
    try {
      // Drop entirely if the message body looks like PII.
      var msg = event.message
        || (event.exception
            && event.exception.values
            && event.exception.values[0]
            && event.exception.values[0].value)
        || '';
      if (looksLikePii(msg)) return null;

      // Scrub URL query params.
      if (event.request && event.request.url) {
        event.request.url = scrubUrl(event.request.url);
      }

      // Never send a user identity beyond an anonymous id.
      event.user = { id: 'anon' };

      // Drop request body + cookies + headers (which often carry auth).
      if (event.request) {
        delete event.request.data;
        delete event.request.cookies;
        delete event.request.headers;
        delete event.request.query_string;
      }

      // Scrub breadcrumb URLs in the event tail too (defence-in-depth — the
      // beforeBreadcrumb hook should already have caught these).
      if (event.breadcrumbs && Array.isArray(event.breadcrumbs)) {
        for (var i = 0; i < event.breadcrumbs.length; i++) {
          var b = event.breadcrumbs[i];
          if (b && b.data && b.data.url) {
            b.data.url = scrubUrl(b.data.url);
          }
        }
      }
      return event;
    } catch (e) {
      // Never let the scrubber itself break Sentry.
      return event;
    }
  }

  function scrubBreadcrumb(breadcrumb) {
    try {
      if (!breadcrumb) return breadcrumb;

      // Drop fetch/xhr breadcrumbs for auth-shaped endpoints so we never
      // see access_token / refresh_token URLs in the breadcrumb trail.
      if ((breadcrumb.category === 'fetch' || breadcrumb.category === 'xhr')
          && breadcrumb.data && breadcrumb.data.url) {
        if (/auth|login|token|oauth|callback|otp|magic/i.test(breadcrumb.data.url)) {
          return null;
        }
        breadcrumb.data.url = scrubUrl(breadcrumb.data.url);
      }

      // Console breadcrumbs that quote PII → drop.
      if (breadcrumb.category === 'console' && breadcrumb.message) {
        if (looksLikePii(breadcrumb.message)) return null;
      }

      // Navigation breadcrumbs (from/to URLs) → scrub.
      if (breadcrumb.category === 'navigation' && breadcrumb.data) {
        if (breadcrumb.data.from) breadcrumb.data.from = scrubUrl(breadcrumb.data.from);
        if (breadcrumb.data.to)   breadcrumb.data.to   = scrubUrl(breadcrumb.data.to);
      }
      return breadcrumb;
    } catch (e) {
      return breadcrumb;
    }
  }

  // ---- Init (gated, defer-safe) ------------------------------------------

  function initSentry() {
    if (!window.Sentry) return;                       // CDN didn't load
    var dsn = window.__SENTRY_DSN__;
    if (!dsn || dsn === '__SENTRY_DSN_PLACEHOLDER__') return;  // not deployed yet

    var release = window.__APP_VERSION__;
    if (!release || release === '__APP_VERSION_PLACEHOLDER__') {
      release = 'landing-v25';
    }

    try {
      var integrations = [];
      if (typeof Sentry.browserTracingIntegration === 'function') {
        integrations.push(Sentry.browserTracingIntegration());
      }
      if (typeof Sentry.replayIntegration === 'function') {
        integrations.push(Sentry.replayIntegration({
          maskAllText: true,
          blockAllMedia: true,
          maskAllInputs: true,
        }));
      }

      Sentry.init({
        dsn: dsn,
        environment: 'production',
        release: release,
        integrations: integrations,
        tracesSampleRate: 0.1,
        replaysSessionSampleRate: 0.0,    // OFF — pure-idle replays too costly
        replaysOnErrorSampleRate: 0.1,    // 10% of error sessions get replayed
        sendDefaultPii: false,
        beforeSend: scrubPii,
        beforeBreadcrumb: scrubBreadcrumb,
        // Cut noise from browser-extension errors and cross-origin scripts
        // that almost always come back as "Script error." with no stack.
        ignoreErrors: [
          'Script error.',
          'ResizeObserver loop limit exceeded',
          'ResizeObserver loop completed with undelivered notifications.',
          'Non-Error promise rejection captured',
        ],
        denyUrls: [
          /extensions\//i,
          /^chrome:\/\//i,
          /^chrome-extension:\/\//i,
          /^moz-extension:\/\//i,
          /^safari-extension:\/\//i,
        ],
      });
    } catch (e) {
      // Sentry init must NEVER break the page. Swallow + console.warn only.
      if (window.console && console.warn) {
        console.warn('[sentry] init failed:', e && e.message);
      }
    }
  }

  if (document.readyState === 'complete') {
    initSentry();
  } else {
    window.addEventListener('load', initSentry, { once: true });
  }
})();
