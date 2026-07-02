/*
 * Advocat geofence loader
 * --------------------------------------------------------------------------
 * Restricts B2C signup / app access in countries where the current product
 * configuration would constitute Unauthorised Practice of Law (UPL) under
 * local bar/RDG/RAO/BGFA/Loi 71-1130/L.247-2012/etc.
 *
 * Audit cross-refs:
 *   docs/security_audit_2026-05-28/findings/10_dach_legal.md     (DE/AT/CH)
 *   docs/security_audit_2026-05-28/findings/11_romance_eu_legal.md (FR/BE/LU/ES/IT/PT)
 *
 * Posture by country:
 *   B2C ALLOW   : FI, EE   (current operating jurisdictions; FI/EE counsel reviewed)
 *   B2B-ONLY    : DE, AT, FR, BE, IT, PT, LU, ES, CH
 *                 → redirect to /b2b-only.html
 *   PASS-THROUGH: everywhere else (no UPL ruling yet; treat as informational use)
 *
 * Detection priority:
 *   1. Cloudflare trace endpoint (/cdn-cgi/trace) — authoritative when GH Pages
 *      is fronted by CF. Returns "loc=XX" line.
 *   2. navigator.language heuristic (de-DE → DE, fr-BE → BE, etc.) as fallback.
 *
 * Fail-safe: if detection cannot complete in 1500 ms, fall back to language
 * heuristic. If that also fails, do NOT block (we prefer false-negative over
 * false-positive for UX — restricted-country users still need to see the
 * B2B-only page if they reach checkout).
 *
 * Override (for QA / staging): ?geo=DE in URL params forces a country.
 *   Cookie advocat_geo_seen=1 prevents re-redirect after user has read the page.
 *
 * Public API: window.advocatGeo = { country, restricted, b2bOnly }
 *   Set after detection completes.
 *
 * MUST load BEFORE _analytics.js and BEFORE any signup/CTA JS.
 */
(function () {
  'use strict';

  // ---- Country posture lists --------------------------------------------
  // B2B-only (B2C blocked) per audit findings 10 and 11.
  // DE/AT/CH per audit 10 §0; FR/BE/IT/PT per audit 11 §0; LU/ES B2B-only
  // for Wave 1 (audit 11 §3-4 — Wave 4 will revisit for ES B2C feasibility).
  var B2B_ONLY = {
    DE: 'Germany',
    AT: 'Austria',
    CH: 'Switzerland',
    FR: 'France',
    BE: 'Belgium',
    LU: 'Luxembourg',
    IT: 'Italy',
    PT: 'Portugal',
    ES: 'Spain'
  };

  // B2C allowed — explicit allowlist. Everything else is treated as
  // "pass-through" informational use (no redirect).
  var B2C_ALLOWED = { FI: 'Finland', EE: 'Estonia' };

  var REDIRECT_URL = '/b2b-only.html';
  var SEEN_COOKIE = 'advocat_geo_seen';
  var SEEN_MAX_AGE_S = 60 * 60 * 24 * 7; // 1 week

  // ---- Utilities --------------------------------------------------------

  function getQueryParam(name) {
    try {
      var p = new URLSearchParams(window.location.search);
      var v = p.get(name);
      return v ? v.toUpperCase() : null;
    } catch (e) { return null; }
  }

  function hasCookie(name) {
    return document.cookie.split('; ').some(function (c) {
      return c.indexOf(name + '=') === 0;
    });
  }

  function setCookie(name, value, maxAgeSec) {
    var attrs = 'Path=/; Max-Age=' + maxAgeSec + '; SameSite=Lax';
    if (location.protocol === 'https:') attrs += '; Secure';
    document.cookie = name + '=' + value + '; ' + attrs;
  }

  function isAlreadyOnB2bPage() {
    // B2B-only landing and for-firms.html are B2B surfaces — never bounce
    // restricted-country visitors away from them.
    return /\/(b2b-only|for-firms)(\.html)?$/i.test(window.location.pathname);
  }

  function hideB2cCtas() {
    // Inject a style tag so we hide before paint completes.
    var css = '.b2c-only{display:none !important;}';
    var s = document.createElement('style');
    s.setAttribute('data-advocat-geo', 'b2c-hidden');
    s.appendChild(document.createTextNode(css));
    (document.head || document.documentElement).appendChild(s);
    // Also annotate <html> for CSS authors (e.g. show .b2b-cta).
    document.documentElement.setAttribute('data-geo-b2b-only', '1');
  }

  function redirectToB2b(country) {
    if (isAlreadyOnB2bPage()) return; // avoid loop
    setCookie(SEEN_COOKIE, '1', SEEN_MAX_AGE_S);
    // Preserve original target for a return-link on the B2B-only page.
    var from = encodeURIComponent(window.location.pathname + window.location.search);
    var url = REDIRECT_URL + '?country=' + encodeURIComponent(country) + '&from=' + from;
    window.location.replace(url);
  }

  // ---- Country detection ------------------------------------------------

  // Best-effort: Cloudflare /cdn-cgi/trace. When the site is fronted by CF this
  // returns plain text containing "loc=XX". On non-CF deployments (GH Pages
  // raw) the endpoint 404s in ~30 ms and we fall back.
  function detectViaCloudflare(timeoutMs) {
    return new Promise(function (resolve) {
      var done = false;
      var tid = setTimeout(function () { if (!done) { done = true; resolve(null); } }, timeoutMs);
      try {
        fetch('/cdn-cgi/trace', { credentials: 'omit', cache: 'no-store' })
          .then(function (r) {
            if (!r.ok) { if (!done) { done = true; clearTimeout(tid); resolve(null); } return null; }
            return r.text();
          })
          .then(function (txt) {
            if (done) return;
            done = true; clearTimeout(tid);
            if (!txt) { resolve(null); return; }
            var m = txt.match(/^loc=([A-Z]{2})/m);
            resolve(m ? m[1] : null);
          })
          .catch(function () { if (!done) { done = true; clearTimeout(tid); resolve(null); } });
      } catch (e) {
        if (!done) { done = true; clearTimeout(tid); resolve(null); }
      }
    });
  }

  // Heuristic fallback — navigator.language. de-DE → DE, fr-FR → FR, etc.
  // Mapping is best-effort: locale-without-region (e.g. plain "de") maps to
  // the dominant restricted country (de → DE). Users from CH browsing in
  // de-CH still match CH correctly.
  function detectViaNavigatorLanguage() {
    try {
      var lang = (navigator.language || (navigator.languages && navigator.languages[0]) || '').toLowerCase();
      if (!lang) return null;
      // 1. Try region tag first: "fr-be" → BE.
      var m = lang.match(/^[a-z]{2,3}-([a-z]{2})$/);
      if (m) {
        var region = m[1].toUpperCase();
        if (B2B_ONLY[region] || B2C_ALLOWED[region]) return region;
      }
      // 2. Plain language → dominant country in restricted list.
      var DOMINANT = {
        de: 'DE', // DE > AT > CH
        fr: 'FR', // FR > BE > LU > CH
        it: 'IT', // IT > CH
        pt: 'PT',
        es: 'ES',
        nl: 'BE', // NL is not restricted (yet), but nl-BE common; map to BE
        fi: 'FI',
        et: 'EE'
      };
      var base = lang.split('-')[0];
      return DOMINANT[base] || null;
    } catch (e) { return null; }
  }

  // ---- Main flow --------------------------------------------------------

  function apply(country, source) {
    var cc = (country || '').toUpperCase();
    window.advocatGeo = {
      country: cc || null,
      source: source || 'unknown',
      restricted: !!B2B_ONLY[cc],
      b2bOnly: !!B2B_ONLY[cc],
      allowed: !!B2C_ALLOWED[cc]
    };
    // Fire a custom event so other scripts can react (e.g. signup form swap).
    try {
      window.dispatchEvent(new CustomEvent('advocat:geo', { detail: window.advocatGeo }));
    } catch (e) { /* IE legacy not supported */ }

    if (!cc) return;
    if (!B2B_ONLY[cc]) return; // pass-through

    // Restricted — hide B2C CTAs immediately and (unless already redirected
    // or user has acknowledged) bounce to the B2B-only page.
    hideB2cCtas();
    if (!hasCookie(SEEN_COOKIE)) {
      redirectToB2b(cc);
    }
  }

  // Manual override for QA: ?geo=DE.
  var override = getQueryParam('geo');
  if (override) {
    apply(override, 'override');
    return;
  }

  // Skip detection on the B2B-only page itself (avoids redirect loop and
  // unnecessary network).
  if (isAlreadyOnB2bPage()) {
    window.advocatGeo = { country: null, source: 'b2b-page', restricted: true, b2bOnly: true, allowed: false };
    return;
  }

  // Primary detection — Cloudflare.
  detectViaCloudflare(1500).then(function (cc) {
    if (cc) { apply(cc, 'cf-trace'); return; }
    // Fallback — navigator.language.
    var fallback = detectViaNavigatorLanguage();
    apply(fallback, fallback ? 'navigator.language' : 'none');
  });
})();
