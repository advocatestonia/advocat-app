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

    ['source', 'medium', 'campaign', 'content', 'term'].forEach(function (k) {
      var v = params.get('utm_' + k);
      if (v) utm[k] = v;
    });

    ['gclid', 'fbclid', 'ttclid'].forEach(function (k) {
      var v = params.get(k);
      if (v) utm[k] = v;
    });

    if (Object.keys(utm).length === 0) return;

    utm.captured_at = new Date().toISOString();
    utm.landing_page = window.location.pathname;

    localStorage.setItem(KEY, JSON.stringify(utm));
  } catch (e) {
    // localStorage may be disabled (private mode, strict policies). Fail silently.
  }
})();
