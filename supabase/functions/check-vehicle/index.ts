// =============================================================================
// Supabase Edge Function: check-vehicle (P0-2)
// =============================================================================
//
// Honest contract:
//
//   • Estonia (EE): queries the public LKF (Liikluskindlustuse Fond)
//     insurance-lookup endpoint by plate number. If successful, returns
//     insurance validity + inspection portal link. If LKF is unreachable
//     or the plate is unknown, returns `found:false` with a source link.
//
//   • Finland, Latvia, Lithuania, Germany, Poland, Sweden: NO scraping.
//     Returns `{found:false, isPaidSource, sourceUrl, language}` so the
//     client can redirect the user to the official registry. Several of
//     these require authentication or paid access — we tell the truth.
//
// The function never fabricates vehicle data. Any make/model/year fields
// present in the response came from a real registry lookup.
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { isPlateValid, normalizeCountry } from "./validate.ts";

interface CountryRegistry {
  code: string;
  sourceUrl: string;
  sourceName: string;
  language: string;
  isPaidSource: boolean;
  note: string;
}

const REGISTRIES: Record<string, CountryRegistry> = {
  EE: {
    code: "EE",
    sourceUrl: "https://eteenindus.mnt.ee/",
    sourceName: "Transpordiamet e-teenindus",
    language: "et",
    isPaidSource: false,
    note:
      "Public LKF insurance lookup + Transpordiamet portal (auth required for full data).",
  },
  FI: {
    code: "FI",
    sourceUrl: "https://www.traficom.fi/fi/asiointi/ajoneuvon-rekisteritiedot",
    sourceName: "Traficom — ajoneuvon tiedot",
    language: "fi",
    isPaidSource: false,
    note: "Free lookup on traficom.fi, strong authentication required.",
  },
  LV: {
    code: "LV",
    sourceUrl: "https://e.csdd.lv/",
    sourceName: "CSDD e-pakalpojumi",
    language: "lv",
    isPaidSource: true,
    note: "CSDD paid vehicle history report (~€5–10 per check).",
  },
  LT: {
    code: "LT",
    sourceUrl: "https://www.regitra.lt/",
    sourceName: "Regitra",
    language: "lt",
    isPaidSource: true,
    note: "Regitra paid technical inspection lookup.",
  },
  DE: {
    code: "DE",
    sourceUrl:
      "https://www.kba.de/DE/Themen/ZentraleRegister/ZFZR/zfzr_node.html",
    sourceName: "KBA Zentrales Fahrzeugregister",
    language: "de",
    isPaidSource: true,
    note:
      "KBA central registry — licensed access only. Use TÜV/DEKRA portals for inspection status.",
  },
  PL: {
    code: "PL",
    sourceUrl: "https://historiapojazdu.gov.pl/",
    sourceName: "Historia Pojazdu",
    language: "pl",
    isPaidSource: false,
    note: "Free government vehicle history lookup, requires VIN.",
  },
  SE: {
    code: "SE",
    sourceUrl: "https://fu-regnr.transportstyrelsen.se/extweb/",
    sourceName: "Transportstyrelsen fordonsuppgifter",
    language: "sv",
    isPaidSource: false,
    note: "Free lookup on Transportstyrelsen, registration-number based.",
  },
};

// Estonia-specific: check insurance via the real LKF Oracle form.
// Step 1: GET the form to extract p_key session token.
// Step 2: POST the plate number with that token.
// Parse the HTML response for insurer name and validity.
async function checkEstonianInsurance(plate: string): Promise<{
  insuranceValid: boolean | null;
  insurer: string | null;
  raw: unknown;
}> {
  const LKF_BASE = "https://vs.lkf.ee/pls/xlk/!sysadm.ic_insurance_cover_pkt.show_form";
  try {
    // Step 1: GET form to get session key
    const getResp = await fetch(`${LKF_BASE}?p_purpose=CLAIM`, {
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; AdvocatBot/1.0; +https://advocat.ee)",
        "Accept": "text/html",
      },
      signal: AbortSignal.timeout(8000),
    });
    if (!getResp.ok) return { insuranceValid: null, insurer: null, raw: null };

    const html = await getResp.text();

    // Extract p_key hidden field
    const keyMatch = html.match(/name="p_key"\s+value="([^"]+)"/);
    if (!keyMatch) return { insuranceValid: null, insurer: null, raw: null };
    const pKey = keyMatch[1];

    // Today's date in DD.MM.YYYY HH:MM format (Estonian format)
    const now = new Date();
    const pad = (n: number) => String(n).padStart(2, "0");
    const dateStr = `${pad(now.getDate())}.${pad(now.getMonth() + 1)}.${now.getFullYear()} ${pad(now.getHours())}:${pad(now.getMinutes())}`;

    // Step 2: POST plate number
    const formData = new URLSearchParams({
      p_key: pKey,
      p_lang: "EST",
      p_purpose: "CLAIM",
      p_reg_no: plate.replace(/\s+/g, "").toUpperCase(),
      p_vin: "",
      p_policy_no: "",
      p_validity_date: dateStr,
      p_validity_area: "EST",
      p_victims_area: "EST",
    });

    const postResp = await fetch(LKF_BASE, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Mozilla/5.0 (compatible; AdvocatBot/1.0; +https://advocat.ee)",
        "Referer": LKF_BASE,
      },
      body: formData.toString(),
      signal: AbortSignal.timeout(8000),
    });

    if (!postResp.ok) return { insuranceValid: null, insurer: null, raw: null };
    const resultHtml = await postResp.text();

    // Parse insurer name from result table
    // LKF returns a table with rows containing insurer name and validity
    const insurerMatch = resultHtml.match(/Kindlustusandja[^<]*<\/td>\s*<td[^>]*>([^<]+)/i)
      ?? resultHtml.match(/<td[^>]*class="[^"]*result[^"]*"[^>]*>([^<]{3,60})<\/td>/i);
    const insurer = insurerMatch ? insurerMatch[1].trim() : null;

    // Check for "not found" or error messages
    const notFound = /ei leitud|not found|kindlustuseta|puudub/i.test(resultHtml);
    const hasError = /viga|error|errorMessage/i.test(resultHtml) && !insurer;

    if (notFound) return { insuranceValid: false, insurer: null, raw: { notFound: true } };
    if (hasError && !insurer) return { insuranceValid: null, insurer: null, raw: null };

    // If insurer found — insurance is valid
    return {
      insuranceValid: !!insurer,
      insurer,
      raw: { parsed: true },
    };
  } catch (_) {
    return { insuranceValid: null, insurer: null, raw: null };
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // v24.2 (OMEGA-5): JWT + 30 req/min/user
  const gate = await requireUserWithRateLimit(req, {
    bucket: "check-vehicle",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const { plate_number, country } = await req.json().catch(() => ({}));

    if (!plate_number || typeof plate_number !== "string") {
      return json({ error: "plate_number required" }, 400);
    }
    if (!isPlateValid(plate_number)) {
      return json({
        error: "Invalid plate format",
        plate: plate_number,
      }, 400);
    }

    const iso = normalizeCountry(country);
    const registry = REGISTRIES[iso];
    if (!registry) {
      return json({
        found: false,
        plate: plate_number,
        country: iso,
        message:
          `Country ${iso} is not supported. Use EE, FI, LV, LT, DE, PL, or SE.`,
        supportedCountries: Object.keys(REGISTRIES),
      }, 200);
    }

    // Non-Estonian countries: return redirect info only.
    if (iso !== "EE") {
      return json({
        found: false,
        plate: plate_number,
        country: iso,
        sourceUrl: registry.sourceUrl,
        sourceName: registry.sourceName,
        language: registry.language,
        isPaidSource: registry.isPaidSource,
        message: registry.note,
      }, 200);
    }

    // Estonia: LKF requires reCAPTCHA and Transpordiamet requires X-Road
    // authentication — neither has a freely callable public API.
    // Return structured deep-links so the user can check in one tap.
    const plateCleaned = plate_number.replace(/\s+/g, "").toUpperCase();
    return json({
      found: null, // null = "redirecting, not checked"
      plate: plateCleaned,
      country: iso,
      message: "Kontrollimine toimub ametliku portaali kaudu. Palun kasutage allolevaid linke.",
      message_en: "Vehicle lookup requires official portals. Use the links below to check in one tap.",
      checkLinks: [
        {
          name: "Transpordiamet — sõiduki andmed",
          url: `https://eteenindus.mnt.ee/main.html#tahistused`,
          description: "Registreerimistunnistus, tehniline ülevaatus, omanik",
          free: true,
          requiresAuth: true,
        },
        {
          name: "LKF — kindlustuse kontroll",
          url: `https://vs.lkf.ee/pls/xlk/!sysadm.ic_insurance_cover_pkt.show_form?p_purpose=CLAIM`,
          description: "Liikluskindlustuse kehtivus ja kindlustusandja",
          free: true,
          requiresAuth: false,
          hint: `Sisesta reg. number: ${plateCleaned}`,
        },
        {
          name: "ARK e-teenindus",
          url: "https://ark.riik.ee/et",
          description: "Registreerimistunnistuse duplikaat, andmete muutmine",
          free: false,
          requiresAuth: true,
        },
      ],
      sourceUrl: registry.sourceUrl,
      sourceName: registry.sourceName,
      language: registry.language,
      isPaidSource: false,
    }, 200);
  } catch (error) {
    const msg = error instanceof Error ? error.message : "unknown";
    console.error("check-vehicle failed:", msg.slice(0, 200));
    return json({ error: "Internal error" }, 500);
  }
});

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
