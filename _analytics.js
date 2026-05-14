/*
 * Advocat unified analytics loader
 * --------------------------------------------------------------------------
 * Consent-gated per GDPR Art 6(1)(a) + ePrivacy Art 5(3).
 *
 * Consent contract (matches existing cookie banner on landing.html/index.html):
 *   localStorage key : "advocat_cookie_consent_v1"
 *   value shape      : { choice: "accept" | "reject" | "dnt", ts, version }
 *   custom event     : "advocat:cookie-consent" with detail.accepted = true
 *
 * Nothing here fires before the user clicks "Accept" (or re-loads a page
 * where a prior accept is already in localStorage).
 *
 * Public API: window.advocatTrack(eventName, params)
 *   Fires the same event to GA4, Meta Pixel, TikTok Pixel — all that are
 *   loaded. Safe to call even before consent (becomes a no-op).
 */
(function () {
  'use strict';

  var GA4_ID         = 'G-J5LGKRTMJ7';
  var META_PIXEL_ID  = 'TBD'; // Owner: set after dashboard.facebook.com/business creates pixel
  var TIKTOK_PIXEL_ID = 'TBD'; // Owner: set after ads.tiktok.com creates pixel

  var loaded = { ga: false, meta: false, tiktok: false };

  function hasConsent() {
    try {
      var raw = localStorage.getItem('advocat_cookie_consent_v1');
      if (!raw) return false;
      var c = JSON.parse(raw);
      return !!(c && c.choice === 'accept');
    } catch (e) {
      return false;
    }
  }

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

  function loadAll() {
    loadGA4();
    loadMetaPixel();
    loadTikTokPixel();
  }

  /**
   * Unified track API. Forwards the same event to every loaded vendor.
   * No-op until consent is given.
   *
   * @param {string} eventName e.g. "purchase", "begin_signup", "tool_used"
   * @param {Object} [params]  e.g. { value: 19.99, currency: "EUR" }
   */
  window.advocatTrack = function (eventName, params) {
    if (!hasConsent()) return;
    params = params || {};
    try { if (window.gtag) window.gtag('event', eventName, params); } catch (e) {}
    try { if (window.fbq)  window.fbq('track', eventName, params); } catch (e) {}
    try { if (window.ttq)  window.ttq.track(eventName, params); } catch (e) {}
  };

  // Bootstrap: load now if consent already given, otherwise wait for the
  // banner to fire the consent event.
  if (hasConsent()) {
    loadAll();
  } else {
    window.addEventListener('advocat:cookie-consent', function (e) {
      if (e && e.detail && e.detail.accepted) loadAll();
    });
  }
})();
