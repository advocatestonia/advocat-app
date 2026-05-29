/*
 * Advocat — per-jurisdiction cookie consent
 * --------------------------------------------------------------------------
 * WAVE 2 FIX W2-13 (2026-05-28). Replaces the single EDPB-baseline banner
 * inlined in index.html with a profile-driven banner whose behaviour is
 * selected from window.advocatGeo (populated by _geofence.js in Wave 1).
 *
 * Audit cross-refs:
 *   docs/security_audit_2026-05-28/findings/10_dach_legal.md     (DE/AT — TTDSG §25 + Planet49)
 *   docs/security_audit_2026-05-28/findings/11_romance_eu_legal.md §7  (FR/ES/IT/BE/LU/PT)
 *
 * Why this exists:
 *   A single EU EDPB-baseline cookie banner FAILS CNIL (FR), AEPD (ES) and
 *   the Garante (IT) by design. Each authority has hard, specific demands
 *   that conflict with a generic banner:
 *     - CNIL Délib. 2020-091/092 + 2022-009 — "Reject all" must be as
 *       prominent as "Accept all", granular per purpose, no pre-ticked.
 *     - AEPD Guía julio 2023 — same baseline plus configuración panel that
 *       is always reachable and a hard 13-month retention recommendation.
 *     - Garante Linee guida cookie 10 giugno 2021 — scroll-to-accept
 *       prohibited; first-layer cannot have "OK" button only; explicit X.
 *     - TTDSG §25 + BGH/LG Köln dark-pattern decisions — Reject must be
 *       on the same layer with equal visual weight; analytics opt-in only.
 *
 * Public contract:
 *   localStorage key  : "advocat_cookie_consent_v2"
 *   stored shape      : {
 *     version: 2,
 *     ts: <epoch ms>,
 *     country: "FR" | "DE" | ... | null,
 *     profile: "FR" | "DE" | ... | "DEFAULT",
 *     choice: "accept_all" | "reject_all" | "custom",
 *     purposes: { necessary: true, analytics: bool, marketing: bool, functional: bool },
 *     expires_at: <epoch ms>   // 13 months FR/ES, 6 months IT, 12 months default
 *   }
 *
 *   Events dispatched on window (consumed by _analytics.js, _utm_capture.js, others):
 *     "advocat:cookie-consent"        — backwards-compat: detail.accepted (any purpose granted)
 *     "advocat:consent:analytics"     — detail.granted: boolean
 *     "advocat:consent:marketing"     — detail.granted: boolean
 *     "advocat:consent:functional"    — detail.granted: boolean
 *
 * Migration v1 → v2:
 *   Legacy key "advocat_cookie_consent_v1" with choice "accept" / "reject" / "dnt".
 *   We DO NOT auto-grant granular purposes from v1 (the user never consented
 *   to per-purpose splits). Instead, we show a "preferences updated" mini
 *   banner with a Manage button. After v2 choice is recorded, v1 is cleared.
 *
 * Wiring requirements (in index.html and every landing/blog page):
 *   <script src="/_geofence.js"></script>   <!-- emits advocat:geo -->
 *   <script src="/_cookie_consent.js" defer></script>  <!-- this file -->
 *   <script src="/_utm_capture.js"></script>
 *   <script src="/_analytics.js" defer></script>
 *
 *   The inline banner block currently in index.html (advCookieBanner) becomes
 *   redundant once this script is wired — but we leave the existing markup
 *   intact and just hide it; deletion happens in a follow-up patch so old
 *   prod pages don't show two banners during cache transition.
 *
 * Smoke checklist: docs/security_audit_2026-05-28/fixes/wave2_cookie_consent_smoke.html
 */
(function () {
  'use strict';

  // -----------------------------------------------------------------------
  // 1. CONFIG: per-jurisdiction profiles.
  // -----------------------------------------------------------------------
  // Each profile follows the strictest authority in its market:
  //   refuseEqualWeight : "Reject all" must be visually equivalent to "Accept all"
  //   granular          : per-purpose toggles required at first layer or one click away
  //   prePopulated      : if true, non-necessary toggles default ON (NEVER true post-Planet49)
  //   cookieLifespanD   : days the recorded consent itself is valid; re-prompt after
  //   xCloseProhibited  : if true, a bare X close button is NOT consent (Garante)
  //   firstLayerNeedsReject : if true, "Reject all" MUST be on layer 1, not behind "Manage"
  //   language          : preferred banner language (overridden by user's chosen UI lang if available)
  //
  var DAY = 24 * 60 * 60 * 1000;
  var MONTH = 30 * DAY;

  var PROFILES = {
    FR: {
      authority: 'CNIL',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 13 * 30, // CNIL recommends max 13 months
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'fr',
      notes: 'CNIL Délib. 2020-091/092 + 2022-009'
    },
    ES: {
      authority: 'AEPD',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 13 * 30, // AEPD Guía julio 2023 — max 13 months
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'es',
      notes: 'AEPD Guía cookies julio 2023'
    },
    IT: {
      authority: 'Garante',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 6 * 30, // Garante: 6 months max recommendation
      xCloseProhibited: true,   // Garante prohibits scroll-to-accept + X-close-as-consent
      firstLayerNeedsReject: true,
      language: 'it',
      notes: 'Provv. Garante 10 giugno 2021 — Linee guida cookie'
    },
    DE: {
      authority: 'BfDI / Landes-LfDIs',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: true,   // LG München / OLG Köln dark-pattern lines
      firstLayerNeedsReject: true,
      language: 'de',
      notes: 'TTDSG §25 + Planet49 (CJEU C-673/17)'
    },
    AT: {
      authority: 'DSB',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: true,
      firstLayerNeedsReject: true,
      language: 'de',
      notes: 'DSG + TKG; DSB cookie-banner enforcement'
    },
    BE: {
      authority: 'APD / GBA',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'fr', // BE is FR/NL/DE; default FR (Brussels Region); see selectProfile()
      notes: 'APD aligned with EDPB; trilingual obligation FR/NL/DE'
    },
    PT: {
      authority: 'CNPD',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'pt',
      notes: 'CNPD; PT-language obligation'
    },
    LU: {
      authority: 'CNPD LU',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'fr', // FR primary; DE/EN also acceptable
      notes: 'CNPD LU; FR + DE working languages'
    },
    FI: {
      authority: 'Tietosuojavaltuutettu',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'fi',
      notes: 'EDPB baseline; FI is current B2C market'
    },
    EE: {
      authority: 'AKI',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'et',
      notes: 'AKI; EDPB baseline; EE is current B2C market'
    },
    DEFAULT: {
      authority: 'EDPB baseline',
      refuseEqualWeight: true,
      granular: true,
      prePopulated: false,
      cookieLifespanD: 12 * 30,
      xCloseProhibited: false,
      firstLayerNeedsReject: true,
      language: 'en',
      notes: 'EDPB Guidelines 03/2022 baseline'
    }
  };

  // BE profile language is selected dynamically: if user-locale is nl-BE / nl,
  // we serve NL; if de-BE / de, DE; otherwise FR.
  function resolveBeLang() {
    try {
      var nav = (navigator.language || '').toLowerCase();
      if (nav.indexOf('nl') === 0) return 'nl';
      if (nav.indexOf('de') === 0) return 'de';
    } catch (e) { /* */ }
    return 'fr';
  }

  function selectProfile(country) {
    var cc = (country || '').toUpperCase();
    if (cc === 'BE') {
      var p = clone(PROFILES.BE);
      p.language = resolveBeLang();
      return p;
    }
    if (PROFILES[cc]) return PROFILES[cc];
    return PROFILES.DEFAULT;
  }

  function clone(o) {
    var r = {}; for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) r[k] = o[k]; return r;
  }

  // -----------------------------------------------------------------------
  // 2. TEXTS (translated; minimum sufficient for the banner UI).
  // -----------------------------------------------------------------------
  // Authority-aligned wording per finding 11 §7 + finding 10 §7.
  var TEXTS = {
    en: {
      title: 'Cookies & privacy',
      body: 'We use strictly necessary cookies to keep the service working. With your consent we may also use analytics, marketing and functional cookies. You can change your choice at any time.',
      accept_all: 'Accept all',
      reject_all: 'Reject all',
      manage: 'Manage preferences',
      save: 'Save preferences',
      back: 'Back',
      necessary: 'Strictly necessary',
      analytics: 'Analytics',
      marketing: 'Marketing',
      functional: 'Functional',
      necessary_desc: 'Required for authentication and security. Always on.',
      analytics_desc: 'Aggregated usage analytics (GA4) to improve the service.',
      marketing_desc: 'Conversion tracking on advertising platforms.',
      functional_desc: 'Optional UX features (e.g. preferences memory).',
      learn_more: 'Privacy Policy',
      authority_label: 'Supervisory authority',
      migrate_msg: 'Cookie preferences updated. Review your settings.',
      migrate_button: 'Review'
    },
    fr: {
      title: 'Cookies et confidentialité',
      body: 'Nous utilisons des cookies strictement nécessaires au fonctionnement du service. Avec votre consentement, nous pouvons également utiliser des cookies d\'analyse, de marketing et fonctionnels. Vous pouvez modifier votre choix à tout moment.',
      accept_all: 'Tout accepter',
      reject_all: 'Tout refuser',
      manage: 'Configurer mes choix',
      save: 'Enregistrer mes choix',
      back: 'Retour',
      necessary: 'Strictement nécessaires',
      analytics: 'Mesure d\'audience',
      marketing: 'Marketing',
      functional: 'Fonctionnels',
      necessary_desc: 'Requis pour l\'authentification et la sécurité. Toujours actifs.',
      analytics_desc: 'Mesure d\'audience agrégée (GA4) pour améliorer le service.',
      marketing_desc: 'Suivi des conversions sur les plateformes publicitaires.',
      functional_desc: 'Fonctionnalités optionnelles (mémorisation des préférences).',
      learn_more: 'Politique de confidentialité',
      authority_label: 'Autorité de contrôle',
      migrate_msg: 'Préférences cookies mises à jour. Vérifiez vos paramètres.',
      migrate_button: 'Vérifier'
    },
    es: {
      title: 'Cookies y privacidad',
      body: 'Utilizamos cookies estrictamente necesarias para el funcionamiento del servicio. Con tu consentimiento, podemos usar también cookies de análisis, marketing y funcionales. Puedes cambiar tu elección en cualquier momento.',
      accept_all: 'Aceptar todo',
      reject_all: 'Rechazar todo',
      manage: 'Configurar preferencias',
      save: 'Guardar preferencias',
      back: 'Volver',
      necessary: 'Estrictamente necesarias',
      analytics: 'Analítica',
      marketing: 'Marketing',
      functional: 'Funcionales',
      necessary_desc: 'Necesarias para la autenticación y la seguridad. Siempre activas.',
      analytics_desc: 'Analítica de uso agregada (GA4) para mejorar el servicio.',
      marketing_desc: 'Seguimiento de conversiones en plataformas publicitarias.',
      functional_desc: 'Funciones opcionales (memoria de preferencias).',
      learn_more: 'Política de privacidad',
      authority_label: 'Autoridad de control',
      migrate_msg: 'Preferencias de cookies actualizadas. Revisa tu configuración.',
      migrate_button: 'Revisar'
    },
    it: {
      title: 'Cookie e privacy',
      body: 'Utilizziamo cookie strettamente necessari per il funzionamento del servizio. Con il tuo consenso possiamo usare anche cookie di analisi, marketing e funzionali. Puoi modificare la tua scelta in qualsiasi momento. Per maggiori dettagli consulta l\'informativa estesa.',
      accept_all: 'Accetta tutto',
      reject_all: 'Rifiuta tutto',
      manage: 'Gestisci preferenze',
      save: 'Salva preferenze',
      back: 'Indietro',
      necessary: 'Strettamente necessari',
      analytics: 'Analitica',
      marketing: 'Marketing',
      functional: 'Funzionali',
      necessary_desc: 'Necessari per autenticazione e sicurezza. Sempre attivi.',
      analytics_desc: 'Analitica d\'uso aggregata (GA4) per migliorare il servizio.',
      marketing_desc: 'Tracciamento conversioni su piattaforme pubblicitarie.',
      functional_desc: 'Funzionalità opzionali (memoria delle preferenze).',
      learn_more: 'Informativa privacy',
      authority_label: 'Autorità di controllo',
      migrate_msg: 'Preferenze cookie aggiornate. Rivedi le tue impostazioni.',
      migrate_button: 'Rivedi'
    },
    de: {
      title: 'Cookies und Datenschutz',
      body: 'Wir verwenden technisch notwendige Cookies, damit der Dienst funktioniert. Mit Ihrer Einwilligung verwenden wir außerdem Analyse-, Marketing- und Funktions-Cookies. Sie können Ihre Einwilligung jederzeit widerrufen.',
      accept_all: 'Alle akzeptieren',
      reject_all: 'Alle ablehnen',
      manage: 'Einstellungen',
      save: 'Auswahl speichern',
      back: 'Zurück',
      necessary: 'Technisch notwendig',
      analytics: 'Analyse',
      marketing: 'Marketing',
      functional: 'Funktional',
      necessary_desc: 'Erforderlich für Anmeldung und Sicherheit. Immer aktiv.',
      analytics_desc: 'Aggregierte Nutzungsanalyse (GA4) zur Verbesserung des Dienstes.',
      marketing_desc: 'Conversion-Tracking auf Werbeplattformen.',
      functional_desc: 'Optionale UX-Funktionen (z. B. Einstellungen merken).',
      learn_more: 'Datenschutzerklärung',
      authority_label: 'Aufsichtsbehörde',
      migrate_msg: 'Cookie-Einstellungen aktualisiert. Bitte prüfen.',
      migrate_button: 'Prüfen'
    },
    nl: {
      title: 'Cookies en privacy',
      body: 'Wij gebruiken strikt noodzakelijke cookies om de dienst te laten werken. Met uw toestemming gebruiken wij ook analyse-, marketing- en functionele cookies. U kunt uw keuze te allen tijde wijzigen.',
      accept_all: 'Alles accepteren',
      reject_all: 'Alles weigeren',
      manage: 'Voorkeuren beheren',
      save: 'Voorkeuren opslaan',
      back: 'Terug',
      necessary: 'Strikt noodzakelijk',
      analytics: 'Analyse',
      marketing: 'Marketing',
      functional: 'Functioneel',
      necessary_desc: 'Vereist voor authenticatie en beveiliging. Altijd aan.',
      analytics_desc: 'Geaggregeerde gebruiksanalyse (GA4) om de dienst te verbeteren.',
      marketing_desc: 'Conversietracking op advertentieplatformen.',
      functional_desc: 'Optionele UX-functies (bijv. onthouden van voorkeuren).',
      learn_more: 'Privacybeleid',
      authority_label: 'Toezichthoudende autoriteit',
      migrate_msg: 'Cookievoorkeuren bijgewerkt. Bekijk uw instellingen.',
      migrate_button: 'Bekijken'
    },
    pt: {
      title: 'Cookies e privacidade',
      body: 'Utilizamos cookies estritamente necessários para o funcionamento do serviço. Com o seu consentimento, podemos também usar cookies de análise, marketing e funcionais. Pode alterar a sua escolha em qualquer momento.',
      accept_all: 'Aceitar tudo',
      reject_all: 'Rejeitar tudo',
      manage: 'Gerir preferências',
      save: 'Guardar preferências',
      back: 'Voltar',
      necessary: 'Estritamente necessários',
      analytics: 'Análise',
      marketing: 'Marketing',
      functional: 'Funcionais',
      necessary_desc: 'Necessários para autenticação e segurança. Sempre ativos.',
      analytics_desc: 'Análise de utilização agregada (GA4) para melhorar o serviço.',
      marketing_desc: 'Acompanhamento de conversões em plataformas publicitárias.',
      functional_desc: 'Funcionalidades opcionais (memória de preferências).',
      learn_more: 'Política de privacidade',
      authority_label: 'Autoridade de controlo',
      migrate_msg: 'Preferências de cookies atualizadas. Reveja as suas definições.',
      migrate_button: 'Rever'
    },
    fi: {
      title: 'Evästeet ja yksityisyys',
      body: 'Käytämme välttämättömiä evästeitä palvelun toimintaan. Suostumuksellasi käytämme myös analytiikka-, markkinointi- ja toiminnallisia evästeitä. Voit muuttaa valintaasi milloin tahansa.',
      accept_all: 'Hyväksy kaikki',
      reject_all: 'Hylkää kaikki',
      manage: 'Hallitse asetuksia',
      save: 'Tallenna asetukset',
      back: 'Takaisin',
      necessary: 'Välttämättömät',
      analytics: 'Analytiikka',
      marketing: 'Markkinointi',
      functional: 'Toiminnalliset',
      necessary_desc: 'Tarvitaan kirjautumiseen ja turvallisuuteen. Aina päällä.',
      analytics_desc: 'Anonyymi käyttöanalytiikka (GA4) palvelun parantamiseksi.',
      marketing_desc: 'Mainontaplatformien konversioseuranta.',
      functional_desc: 'Valinnaiset UX-toiminnot (esim. asetusten muistaminen).',
      learn_more: 'Tietosuojakäytäntö',
      authority_label: 'Valvontaviranomainen',
      migrate_msg: 'Evästeasetukset päivitetty. Tarkista asetuksesi.',
      migrate_button: 'Tarkista'
    },
    et: {
      title: 'Küpsised ja privaatsus',
      body: 'Kasutame teenuse toimimiseks rangelt vajalikke küpsiseid. Sinu nõusolekul kasutame ka analüütika-, turunduse- ja funktsionaalsuse küpsiseid. Saad oma valikut igal ajal muuta.',
      accept_all: 'Nõustu kõigega',
      reject_all: 'Keeldu kõigest',
      manage: 'Halda eelistusi',
      save: 'Salvesta eelistused',
      back: 'Tagasi',
      necessary: 'Rangelt vajalikud',
      analytics: 'Analüütika',
      marketing: 'Turundus',
      functional: 'Funktsionaalsed',
      necessary_desc: 'Vajalik autentimiseks ja turvalisuseks. Alati sees.',
      analytics_desc: 'Anonüümne kasutusanalüütika (GA4) teenuse parandamiseks.',
      marketing_desc: 'Konversioonide jälgimine reklaamplatvormidel.',
      functional_desc: 'Valikulised UX-funktsioonid (nt eelistuste mäletamine).',
      learn_more: 'Privaatsuspoliitika',
      authority_label: 'Järelevalveasutus',
      migrate_msg: 'Küpsiseeelistused uuendatud. Vaata oma seaded üle.',
      migrate_button: 'Vaata'
    }
  };

  function textsFor(profile) {
    var lang = profile.language || 'en';
    return TEXTS[lang] || TEXTS.en;
  }

  // -----------------------------------------------------------------------
  // 3. STORAGE: v2 read/write + v1 migration.
  // -----------------------------------------------------------------------
  var V2_KEY = 'advocat_cookie_consent_v2';
  var V1_KEY = 'advocat_cookie_consent_v1';

  function readV2() {
    try {
      var raw = localStorage.getItem(V2_KEY);
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (!parsed || parsed.version !== 2) return null;
      // Expiry check.
      if (parsed.expires_at && Date.now() > parsed.expires_at) return null;
      // Sanity check shape.
      if (!parsed.purposes || typeof parsed.purposes.analytics !== 'boolean') return null;
      return parsed;
    } catch (e) { return null; }
  }

  function readV1() {
    try {
      var raw = localStorage.getItem(V1_KEY);
      if (!raw) return null;
      var c = JSON.parse(raw);
      if (!c || !c.choice) return null;
      return c;
    } catch (e) { return null; }
  }

  function writeV2(record) {
    try {
      localStorage.setItem(V2_KEY, JSON.stringify(record));
      // Clear v1 once v2 is recorded.
      try { localStorage.removeItem(V1_KEY); } catch (_) {}
    } catch (e) { /* private mode etc. */ }
  }

  // -----------------------------------------------------------------------
  // 4. EVENT EMISSION.
  // -----------------------------------------------------------------------
  // _analytics.js (current) listens on "advocat:cookie-consent" with
  // detail.accepted. _utm_capture.js does NOT consent-gate (UTM is first-party
  // functional per its own header). For granular gating downstream, we also
  // dispatch per-purpose events.
  function emitConsent(record) {
    var anyGranted = !!(record.purposes.analytics || record.purposes.marketing || record.purposes.functional);
    try {
      window.dispatchEvent(new CustomEvent('advocat:cookie-consent', {
        detail: {
          accepted: anyGranted,
          choice: record.choice,
          purposes: record.purposes,
          country: record.country,
          version: 2
        }
      }));
    } catch (e) { /* legacy browser */ }

    ['analytics', 'marketing', 'functional'].forEach(function (purpose) {
      try {
        window.dispatchEvent(new CustomEvent('advocat:consent:' + purpose, {
          detail: { granted: !!record.purposes[purpose] }
        }));
      } catch (e) { /* legacy */ }
    });
  }

  // -----------------------------------------------------------------------
  // 5. DOM RENDERING.
  // -----------------------------------------------------------------------
  // We render OUR banner into a dedicated container and hide the legacy
  // advCookieBanner element if present. This avoids deleting markup in
  // index.html during the cache-bust window.
  var CONTAINER_ID = 'advCookieConsent';

  function injectStyles() {
    if (document.getElementById('advCookieConsentStyles')) return;
    var css = ''
      + '#' + CONTAINER_ID + ' { position: fixed; left: 16px; right: 16px; bottom: 16px;'
      + '  background: #0F1B35; color: #fff; border: 1px solid rgba(143,221,221,0.35);'
      + '  border-radius: 12px; padding: 16px 18px;'
      + '  font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;'
      + '  box-shadow: 0 8px 32px rgba(0,0,0,0.4); z-index: 999999; max-width: 720px; margin: 0 auto;'
      + '  display: none; }'
      + '#' + CONTAINER_ID + '.show { display: block; }'
      + '#' + CONTAINER_ID + ' h3 { font-size: 16px; font-weight: 700; margin: 0 0 6px; }'
      + '#' + CONTAINER_ID + ' p { margin: 0 0 12px; color: #cbd5e1; }'
      + '#' + CONTAINER_ID + ' a { color: #8fd; text-decoration: underline; }'
      + '#' + CONTAINER_ID + ' .advCcRow { display: flex; gap: 10px; flex-wrap: wrap; align-items: stretch; }'
      // Reject + Accept buttons MUST be equal-weight. Same min-width, same height,
      // same border-radius, same font-weight. Only the color differs (semantic
      // — both are equally easy to click).
      + '#' + CONTAINER_ID + ' .advCcBtn { flex: 1 1 auto; min-width: 140px; min-height: 44px;'
      + '  padding: 10px 14px; border: 0; border-radius: 8px; font-weight: 600; font-size: 14px;'
      + '  cursor: pointer; }'
      + '#' + CONTAINER_ID + ' .advCcAccept { background: #14B8A6; color: #fff; }'
      + '#' + CONTAINER_ID + ' .advCcReject { background: #334155; color: #fff; }'
      + '#' + CONTAINER_ID + ' .advCcManage { background: transparent; color: #8fd;'
      + '  border: 1px solid rgba(143,221,221,0.45); }'
      + '#' + CONTAINER_ID + ' .advCcAuthority { font-size: 11px; color: #94a3b8; margin-top: 10px; }'
      + '#' + CONTAINER_ID + ' .advCcPurposes { margin: 12px 0; }'
      + '#' + CONTAINER_ID + ' .advCcPurpose { display: flex; gap: 12px; padding: 10px 0;'
      + '  border-top: 1px solid rgba(255,255,255,0.08); }'
      + '#' + CONTAINER_ID + ' .advCcPurpose:first-child { border-top: 0; }'
      + '#' + CONTAINER_ID + ' .advCcPurpose label { font-weight: 600; }'
      + '#' + CONTAINER_ID + ' .advCcPurpose small { color: #94a3b8; display: block; margin-top: 2px; font-weight: normal; }'
      + '#' + CONTAINER_ID + ' .advCcSwitch { flex: 0 0 auto; align-self: center; }'
      + '#' + CONTAINER_ID + ' .advCcSwitch input { width: 18px; height: 18px; }'
      + '#' + CONTAINER_ID + ' .advCcSwitch input:disabled { opacity: 0.5; }'
      + '#' + CONTAINER_ID + '.minimal p { margin-bottom: 8px; }'
      // Hide the legacy v1 banner if both exist (prevents double-display
      // during cache transition).
      + 'body.advCcV2Active #advCookieBanner { display: none !important; }'
      + '@media (max-width: 480px) {'
      + '  #' + CONTAINER_ID + ' { left: 8px; right: 8px; bottom: 8px; padding: 14px; }'
      + '  #' + CONTAINER_ID + ' .advCcBtn { width: 100%; flex: 1 1 100%; }'
      + '}';
    var s = document.createElement('style');
    s.id = 'advCookieConsentStyles';
    s.appendChild(document.createTextNode(css));
    (document.head || document.documentElement).appendChild(s);
  }

  function hideLegacyBanner() {
    try { document.body.classList.add('advCcV2Active'); } catch (_) {}
  }

  function ensureContainer() {
    var el = document.getElementById(CONTAINER_ID);
    if (el) return el;
    el = document.createElement('div');
    el.id = CONTAINER_ID;
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-modal', 'false');
    el.setAttribute('aria-labelledby', 'advCcTitle');
    el.setAttribute('aria-describedby', 'advCcBody');
    // Insert at end of body so it floats above content.
    (document.body || document.documentElement).appendChild(el);
    return el;
  }

  // Render layer 1 (the initial banner with Accept all / Reject all / Manage).
  function renderLayer1(profile, t) {
    injectStyles();
    hideLegacyBanner();
    var el = ensureContainer();
    el.className = 'show';

    // The Manage button is ALSO equal-weight visually so users discover
    // granular controls. Per CNIL/AEPD/Garante, Reject must appear here too,
    // not behind "Manage". We satisfy by emitting all three at layer 1.
    el.innerHTML = ''
      + '<h3 id="advCcTitle">' + esc(t.title) + '</h3>'
      + '<p id="advCcBody">' + esc(t.body) + ' '
      +   '<a href="/privacy.html" target="_blank" rel="noopener">' + esc(t.learn_more) + '</a>'
      + '</p>'
      + '<div class="advCcRow">'
      +   '<button type="button" class="advCcBtn advCcAccept" data-action="accept_all">' + esc(t.accept_all) + '</button>'
      +   '<button type="button" class="advCcBtn advCcReject" data-action="reject_all">' + esc(t.reject_all) + '</button>'
      +   '<button type="button" class="advCcBtn advCcManage" data-action="manage">' + esc(t.manage) + '</button>'
      + '</div>'
      + '<div class="advCcAuthority">' + esc(t.authority_label) + ': ' + esc(profile.authority) + '</div>';

    // Wire up clicks.
    Array.prototype.forEach.call(el.querySelectorAll('button[data-action]'), function (b) {
      b.addEventListener('click', function (ev) {
        ev.preventDefault();
        var a = b.getAttribute('data-action');
        if (a === 'accept_all') return recordChoice(profile, 'accept_all', {
          necessary: true, analytics: true, marketing: true, functional: true
        });
        if (a === 'reject_all') return recordChoice(profile, 'reject_all', {
          necessary: true, analytics: false, marketing: false, functional: false
        });
        if (a === 'manage') return renderLayer2(profile, t);
      });
    });

    // NOTE: per Garante/Planet49/TTDSG — no X-close button. Closing the
    // banner without a decision MUST NOT be treated as consent. We simply
    // do not provide an X. Esc key is also ignored.
  }

  // Render layer 2 (the granular preferences panel).
  function renderLayer2(profile, t) {
    var el = ensureContainer();
    el.className = 'show';
    // Pre-populated must be FALSE for non-necessary per Planet49 (CJEU C-673/17).
    // We default analytics/marketing/functional to OFF — the user opts in.
    var defaults = profile.prePopulated
      ? { necessary: true, analytics: true, marketing: true, functional: true }
      : { necessary: true, analytics: false, marketing: false, functional: false };

    el.innerHTML = ''
      + '<h3 id="advCcTitle">' + esc(t.manage) + '</h3>'
      + '<div class="advCcPurposes" role="group" aria-label="' + esc(t.manage) + '">'
      +   purposeRow('necessary', t.necessary, t.necessary_desc, defaults.necessary, true)
      +   purposeRow('analytics', t.analytics, t.analytics_desc, defaults.analytics, false)
      +   purposeRow('marketing', t.marketing, t.marketing_desc, defaults.marketing, false)
      +   purposeRow('functional', t.functional, t.functional_desc, defaults.functional, false)
      + '</div>'
      + '<div class="advCcRow">'
      +   '<button type="button" class="advCcBtn advCcAccept" data-action="save">' + esc(t.save) + '</button>'
      +   '<button type="button" class="advCcBtn advCcReject" data-action="reject_all">' + esc(t.reject_all) + '</button>'
      +   '<button type="button" class="advCcBtn advCcManage" data-action="back">' + esc(t.back) + '</button>'
      + '</div>'
      + '<div class="advCcAuthority">' + esc(t.authority_label) + ': ' + esc(profile.authority) + '</div>';

    Array.prototype.forEach.call(el.querySelectorAll('button[data-action]'), function (b) {
      b.addEventListener('click', function (ev) {
        ev.preventDefault();
        var a = b.getAttribute('data-action');
        if (a === 'save') {
          var purposes = {
            necessary: true,
            analytics: !!document.getElementById('advCcPurpose_analytics') && document.getElementById('advCcPurpose_analytics').checked,
            marketing: !!document.getElementById('advCcPurpose_marketing') && document.getElementById('advCcPurpose_marketing').checked,
            functional: !!document.getElementById('advCcPurpose_functional') && document.getElementById('advCcPurpose_functional').checked
          };
          var anyOptional = purposes.analytics || purposes.marketing || purposes.functional;
          var choice = anyOptional
            ? ((purposes.analytics && purposes.marketing && purposes.functional) ? 'accept_all' : 'custom')
            : 'reject_all';
          return recordChoice(profile, choice, purposes);
        }
        if (a === 'reject_all') return recordChoice(profile, 'reject_all', {
          necessary: true, analytics: false, marketing: false, functional: false
        });
        if (a === 'back') return renderLayer1(profile, t);
      });
    });
  }

  function purposeRow(key, label, desc, checked, locked) {
    var id = 'advCcPurpose_' + key;
    var disabledAttr = locked ? ' disabled checked' : (checked ? ' checked' : '');
    return ''
      + '<div class="advCcPurpose">'
      +   '<div style="flex:1 1 auto;">'
      +     '<label for="' + id + '">' + esc(label) + '</label>'
      +     '<small>' + esc(desc) + '</small>'
      +   '</div>'
      +   '<div class="advCcSwitch">'
      +     '<input type="checkbox" id="' + id + '" data-purpose="' + key + '"' + disabledAttr + '>'
      +   '</div>'
      + '</div>';
  }

  // Mini "preferences updated" notice for v1 → v2 migration.
  function renderMigrationNotice(profile, t) {
    injectStyles();
    hideLegacyBanner();
    var el = ensureContainer();
    el.className = 'show minimal';
    el.innerHTML = ''
      + '<p>' + esc(t.migrate_msg) + '</p>'
      + '<div class="advCcRow">'
      +   '<button type="button" class="advCcBtn advCcManage" data-action="manage">' + esc(t.migrate_button) + '</button>'
      + '</div>';
    var btn = el.querySelector('button[data-action="manage"]');
    if (btn) {
      btn.addEventListener('click', function (ev) {
        ev.preventDefault();
        renderLayer1(profile, t);
      });
    }
  }

  function hideBanner() {
    var el = document.getElementById(CONTAINER_ID);
    if (el) el.className = '';
  }

  // -----------------------------------------------------------------------
  // 6. UTILITIES.
  // -----------------------------------------------------------------------
  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  // -----------------------------------------------------------------------
  // 7. RECORDING + EMISSION.
  // -----------------------------------------------------------------------
  function recordChoice(profile, choice, purposes) {
    var now = Date.now();
    var record = {
      version: 2,
      ts: now,
      country: window.advocatGeo && window.advocatGeo.country ? window.advocatGeo.country : null,
      profile: detectProfileKey(profile),
      choice: choice,
      purposes: purposes,
      expires_at: now + (profile.cookieLifespanD * DAY),
      authority: profile.authority
    };
    writeV2(record);
    hideBanner();
    emitConsent(record);
  }

  function detectProfileKey(profile) {
    for (var k in PROFILES) {
      if (PROFILES[k] === profile) return k;
      // BE profile is cloned in selectProfile — match by authority as fallback.
      if (PROFILES[k].authority === profile.authority) return k;
    }
    return 'DEFAULT';
  }

  // Honor Do-Not-Track: treat as a reject-all with no banner.
  function isDnt() {
    try {
      if (navigator.doNotTrack === '1' || window.doNotTrack === '1') return true;
      if (navigator.globalPrivacyControl === true) return true;
    } catch (e) { /* */ }
    return false;
  }

  // -----------------------------------------------------------------------
  // 8. BOOTSTRAP.
  // -----------------------------------------------------------------------
  function boot() {
    // 8.1 Existing valid v2 record — replay events for downstream and exit.
    var existing = readV2();
    if (existing) {
      emitConsent(existing);
      return;
    }

    // 8.2 DNT / GPC — record an implicit reject-all and skip the banner.
    if (isDnt()) {
      var dntProfile = PROFILES.DEFAULT;
      // Use current geo if known so country/profile fields are accurate.
      var ccDnt = window.advocatGeo && window.advocatGeo.country;
      if (ccDnt) dntProfile = selectProfile(ccDnt);
      recordChoice(dntProfile, 'reject_all', {
        necessary: true, analytics: false, marketing: false, functional: false
      });
      return;
    }

    // 8.3 Wait for geo, then render. If geofence already resolved
    // (window.advocatGeo is set), proceed immediately.
    function start() {
      var cc = window.advocatGeo && window.advocatGeo.country ? window.advocatGeo.country : null;
      var profile = selectProfile(cc);
      var t = textsFor(profile);

      // v1 migration: if a v1 record exists and was "accept", show the
      // mini "preferences updated" banner (NOT auto-grant).
      var v1 = readV1();
      if (v1 && v1.choice === 'accept') {
        renderMigrationNotice(profile, t);
        return;
      }
      // If v1 was "reject" or "dnt", record a v2 reject-all (preserve choice)
      // and exit silently.
      if (v1 && (v1.choice === 'reject' || v1.choice === 'dnt')) {
        recordChoice(profile, 'reject_all', {
          necessary: true, analytics: false, marketing: false, functional: false
        });
        return;
      }

      // Fresh visit — show layer 1.
      renderLayer1(profile, t);
    }

    if (window.advocatGeo) {
      start();
    } else {
      // _geofence.js dispatches advocat:geo when detection completes
      // (success OR failure — DEFAULT profile is used in the latter case).
      var started = false;
      function once() {
        if (started) return;
        started = true;
        start();
      }
      window.addEventListener('advocat:geo', once);
      // Hard fallback: if geo never resolves (e.g. on a page without
      // _geofence.js, or _geofence.js failed silently), start with DEFAULT
      // profile after 2s.
      setTimeout(once, 2000);
    }
  }

  // Run on DOMContentLoaded (we need document.body to exist).
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

  // -----------------------------------------------------------------------
  // 9. PUBLIC API.
  // -----------------------------------------------------------------------
  // Allows the footer "Manage cookies" link to re-open the banner without
  // wiping localStorage.
  window.advocatCookieConsent = {
    open: function () {
      var cc = window.advocatGeo && window.advocatGeo.country ? window.advocatGeo.country : null;
      var profile = selectProfile(cc);
      var t = textsFor(profile);
      renderLayer1(profile, t);
    },
    reset: function () {
      try { localStorage.removeItem(V2_KEY); } catch (_) {}
      try { localStorage.removeItem(V1_KEY); } catch (_) {}
      this.open();
    },
    get: function () { return readV2(); },
    PROFILES: PROFILES // exposed for smoke test only; do not mutate
  };
})();
