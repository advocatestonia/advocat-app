/*
 * Advocat — UTM / click-id capture
 * --------------------------------------------------------------------------
 * Captures attribution params from the landing URL and persists them to
 * localStorage so the Flutter app can read them at signup / checkout and
 * forward them to Stripe metadata.
 *
 * Captured keys:
 *   utm_source, utm_medium, utm_campaign, utm_content, utm_term
 *   gclid  (Google Ads click ID)
 *   fbclid (Meta click ID)
 *   ttclid (TikTok click ID)
 *
 * Storage:
 *   localStorage key "advocat:utm" -> JSON
 *     {
 *       source, medium, campaign, content, term,
 *       gclid, fbclid, ttclid,
 *       captured_at: ISO timestamp,
 *       landing_page: pathname
 *     }
 *
 * Does NOT require consent — UTMs are first-party functional data needed to
 * fulfil the user's own checkout intent. No third-party network calls here.
 * If you later treat UTMs as analytics-only, gate this on consent too.
 *
 * Safe to load on every entry page; later loads do not overwrite an earlier
 * capture (first-touch attribution).
 *
 * Security: F4 (WAVE 1, 2026-05-28).
 *   Without CSP-Phase-3 nonces, an attacker who manages to inject `?utm_source=`
 *   with HTML-bearing content could ship that to any later page that renders
 *   the value (e.g. an admin dashboard). We allowlist to printable ASCII
 *   safe-chars (alnum + `._-`) and cap at 80 chars to neutralise that surface.
 */
(function () {
  'use strict';

  try {
    var KEY = 'advocat:utm';
    // First-touch: don't overwrite if we already have data from an earlier
    // session. Set last_touch separately if needed in the future.
    if (localStorage.getItem(KEY)) return;

    var params = new URLSearchParams(window.location.search);
    var utm = {};

    // F4 (WAVE 1, 2026-05-28) — sanitiser.
    // Allowed: A-Z a-z 0-9 . _ - (the union of what Google/Meta/TikTok
    // actually emit + standard URL-safe punctuation). Anything else is a
    // sign of injection or accidental copy-paste, so we drop the whole
    // value. Cap length at 80 chars — real UTMs are <=50.
    var SAFE_RE = /^[a-zA-Z0-9._-]+$/;
    var MAX_LEN = 80;
    function sanitise(v) {
      if (typeof v !== 'string') return null;
      if (v.length === 0 || v.length > MAX_LEN) return null;
      return SAFE_RE.test(v) ? v : null;
    }

    ['source', 'medium', 'campaign', 'content', 'term'].forEach(function (k) {
      var raw = params.get('utm_' + k);
      var v = sanitise(raw);
      if (v) utm[k] = v;
    });

    ['gclid', 'fbclid', 'ttclid'].forEach(function (k) {
      var raw = params.get(k);
      var v = sanitise(raw);
      if (v) utm[k] = v;
    });

    if (Object.keys(utm).length === 0) return;

    utm.captured_at = new Date().toISOString();
    // landing_page is our own pathname (not attacker-controlled), but cap
    // it defensively anyway so a pathological URL can't blow up storage.
    var path = window.location.pathname || '/';
    utm.landing_page = path.length > 200 ? path.slice(0, 200) : path;

    localStorage.setItem(KEY, JSON.stringify(utm));
  } catch (e) {
    // localStorage may be disabled (private mode, strict policies). Fail silently.
  }
})();
