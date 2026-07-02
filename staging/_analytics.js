/*
 * Advocat unified analytics loader
 * --------------------------------------------------------------------------
 * Consent-gated per GDPR Art 6(1)(a) + ePrivacy Art 5(3) + TTDSG §25 (DE).
 *
 * WAVE 2 (2026-05-28) — W2-13: granular consent. Wave 1 used a single
 * "any consent = load everything" gate. That fails CNIL / AEPD / Garante /
 * TTDSG by design — each vendor has a different lawful purpose:
 *
 *   GA4          → analytics purpose
 *   Meta Pixel   → marketing purpose
 *   TikTok Pixel → marketing purpose
 *
 * We now listen for per-purpose events from _cookie_consent.js v2:
 *   "advocat:consent:analytics"   { granted: bool } → loads GA4
 *   "advocat:consent:marketing"   { granted: bool } → loads Meta + TikTok
 *
 * Backwards compatible with v1:
 *   localStorage "advocat_cookie_consent_v1" with choice "accept" → still
 *     triggers everything (single bucket); recorded migration runs in
 *     _cookie_consent.js so this path is only hit on pages without the v2
 *     loader (unlikely).
 *
 * v2 storage:
 *   localStorage "advocat_cookie_consent_v2"
 *     { version, ts, country, profile, choice, purposes: { analytics, marketing, functional }, expires_at }
 *
 * Public API: window.advocatTrack(eventName, params)
 *   Routes per-vendor based on which loaders are active. Safe to call any
 *   time — no-op until at least one vendor is loaded.
 */
(function () {
  'use strict';

  // F4 (WAVE 1, 2026-05-28) — freeze the pixel config so attacker JS that
  // lands on the page (chained from a stored XSS) cannot rewrite META_PIXEL_ID
  // to its own ID and exfil PII via track() calls before the legit loader
  // initialises. Object.freeze is shallow but these are primitives, so the
  // values are now truly immutable for the lifetime of the page.
  var PIXEL_CONFIG = Object.freeze({
    GA4_ID:          'G-J5LGKRTMJ7',
    META_PIXEL_ID:   'TBD', // Owner: set after dashboard.facebook.com/business creates pixel
    TIKTOK_PIXEL_ID: 'TBD', // Owner: set after ads.tiktok.com creates pixel
  });
  var GA4_ID          = PIXEL_CONFIG.GA4_ID;
  var META_PIXEL_ID   = PIXEL_CONFIG.META_PIXEL_ID;
  var TIKTOK_PIXEL_ID = PIXEL_CONFIG.TIKTOK_PIXEL_ID;

  var loaded = { ga: false, meta: false, tiktok: false };

  // ---------- Consent checks (v2 first, v1 fallback) ---------------------

  function readV2() {
    try {
      var raw = localStorage.getItem('advocat_cookie_consent_v2');
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (!parsed || parsed.version !== 2 || !parsed.purposes) return null;
      if (parsed.expires_at && Date.now() > parsed.expires_at) return null;
      return parsed;
    } catch (e) { return null; }
  }

  function readV1() {
    try {
      var raw = localStorage.getItem('advocat_cookie_consent_v1');
      if (!raw) return null;
      var c = JSON.parse(raw);
      if (c && c.choice === 'accept') return c;
      return null;
    } catch (e) { return null; }
  }

  function hasAnalyticsConsent() {
    var v2 = readV2();
    if (v2) return !!v2.purposes.analytics;
    // v1: "accept" = analytics granted (single-bucket).
    return !!readV1();
  }

  function hasMarketingConsent() {
    var v2 = readV2();
    if (v2) return !!v2.purposes.marketing;
    // v1: "accept" = marketing granted (single-bucket).
    return !!readV1();
  }

  // ---------- Vendor loaders ---------------------------------------------

  function loadGA4() {
    if (loaded.ga) return;
    loaded.ga = true;
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', GA4_ID, {
      anonymize_ip: true,
      cookie_flags: 'samesite=lax;secure'
    });
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA4_ID;
    document.head.appendChild(s);
  }

  function loadMetaPixel() {
    if (loaded.meta) return;
    if (!META_PIXEL_ID || META_PIXEL_ID === 'TBD') return;
    loaded.meta = true;
    !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window,document,'script','https://connect.facebook.net/en_US/fbevents.js');
    window.fbq('init', META_PIXEL_ID);
    window.fbq('track', 'PageView');
  }

  function loadTikTokPixel() {
    if (loaded.tiktok) return;
    if (!TIKTOK_PIXEL_ID || TIKTOK_PIXEL_ID === 'TBD') return;
    loaded.tiktok = true;
    !function (w, d, t) {
      w.TiktokAnalyticsObject = t;
      var ttq = w[t] = w[t] || [];
      ttq.methods = ["page","track","identify","instances","debug","on","off","once","ready","alias","group","enableCookie","disableCookie"];
      ttq.setAndDefer = function (t, e) { t[e] = function () { t.push([e].concat(Array.prototype.slice.call(arguments, 0))); }; };
      for (var i = 0; i < ttq.methods.length; i++) ttq.setAndDefer(ttq, ttq.methods[i]);
      ttq.instance = function (t) { for (var e = ttq._i[t] || [], n = 0; n < ttq.methods.length; n++) ttq.setAndDefer(e, ttq.methods[n]); return e; };
      ttq.load = function (e, n) {
        var i = "https://analytics.tiktok.com/i18n/pixel/events.js";
        ttq._i = ttq._i || {}; ttq._i[e] = []; ttq._i[e]._u = i;
        ttq._t = ttq._t || {}; ttq._t[e] = +new Date;
        ttq._o = ttq._o || {}; ttq._o[e] = n || {};
        var o = document.createElement("script");
        o.type = "text/javascript"; o.async = !0;
        o.src = i + "?sdkid=" + e + "&lib=" + t;
        var a = document.getElementsByTagName("script")[0];
        a.parentNode.insertBefore(o, a);
      };
      ttq.load(TIKTOK_PIXEL_ID);
      ttq.page();
    }(window, document, 'ttq');
  }

  // ---------- Purpose router ---------------------------------------------

  function applyAnalyticsConsent(granted) {
    if (granted) loadGA4();
    // No tear-down once loaded — page reload required to revoke. UI flow
    // should encourage that via the cookie-management screen.
  }

  function applyMarketingConsent(granted) {
    if (granted) {
      loadMetaPixel();
      loadTikTokPixel();
    }
  }

  /**
   * Unified track API. Forwards the same event to every loaded vendor.
   * No-op until at least one vendor is loaded.
   *
   * @param {string} eventName e.g. "purchase", "begin_signup", "tool_used"
   * @param {Object} [params]  e.g. { value: 19.99, currency: "EUR" }
   */
  window.advocatTrack = function (eventName, params) {
    params = params || {};
    try { if (window.gtag) window.gtag('event', eventName, params); } catch (e) {}
    try { if (window.fbq)  window.fbq('track', eventName, params); } catch (e) {}
    try { if (window.ttq)  window.ttq.track(eventName, params); } catch (e) {}
  };

  // ---------- Bootstrap --------------------------------------------------

  // 1. If v2 record already exists at load time, fire what's granted now.
  applyAnalyticsConsent(hasAnalyticsConsent());
  applyMarketingConsent(hasMarketingConsent());

  // 2. Subscribe to granular v2 events — fired by _cookie_consent.js when
  //    the user picks per-purpose toggles.
  window.addEventListener('advocat:consent:analytics', function (e) {
    if (e && e.detail) applyAnalyticsConsent(!!e.detail.granted);
  });
  window.addEventListener('advocat:consent:marketing', function (e) {
    if (e && e.detail) applyMarketingConsent(!!e.detail.granted);
  });

  // 3. Backwards compatibility with v1 event ("advocat:cookie-consent" with
  //    detail.accepted). v2 also dispatches this event (with the same
  //    detail.accepted = any-granted) so pages still on the v1 banner keep
  //    working. We re-read storage on the event to honour granular state.
  window.addEventListener('advocat:cookie-consent', function (e) {
    if (!e || !e.detail) return;
    // If v2 detail.purposes exists, prefer it.
    if (e.detail.purposes) {
      applyAnalyticsConsent(!!e.detail.purposes.analytics);
      applyMarketingConsent(!!e.detail.purposes.marketing);
      return;
    }
    // v1 single-bucket: detail.accepted true → load everything.
    if (e.detail.accepted === true) {
      applyAnalyticsConsent(true);
      applyMarketingConsent(true);
    }
  });
})();
