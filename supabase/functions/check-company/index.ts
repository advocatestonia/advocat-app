// check-company Edge Function
// -----------------------------------------------------------------------------
// Looks up a company in national business registries (Estonia — live scrape;
// other countries — redirect links).
//
// v24.2 hardening (OMEGA-5): JWT required, 30 req/min/user, CORS advocat.ee
// only, defensive against anonymous scrapers (ariregister will rate-limit us
// if we don't protect our own function first).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "check-company",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const { company_name, country } = await req.json();

    if (!company_name) {
      return new Response(
        JSON.stringify({ error: "company_name required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Estonian registry — real API call
    if (
      !country ||
      country.toLowerCase() === "estonia" ||
      country.toLowerCase() === "eesti" ||
      country.toLowerCase() === "ee"
    ) {
      const url = `https://ariregister.rik.ee/est/api/autocomplete?q=${encodeURIComponent(company_name)}`;
      const response = await fetch(url);
      const raw = await response.json();

      // API returns { status: "OK", data: [...] }
      const items = Array.isArray(raw) ? raw : (raw?.data ?? []);

      if (items.length > 0) {
        const statusMap: Record<string, string> = {
          R: "Registered",
          L: "Liquidated",
          N: "Deleted",
          K: "Bankruptcy",
        };

        const companies = items.slice(0, 5).map((c: any) => ({
          name: c.name || c.nimi || company_name,
          registry_code: String(c.reg_code || c.ariregistri_kood || ""),
          status: statusMap[c.status] || c.status || "unknown",
          status_code: c.status || "",
          address: c.legal_address || c.aadress || "",
          type: c.legal_form || c.oiguslik_vorm || "",
          url: c.url || "",
          historical_names: c.historical_names || [],
        }));

        // Fetch detailed info by scraping the company HTML page.
        // SECURITY: the server-side scrape URL is built ONLY from the
        // registry_code (constrained to digits) pinned to the ariregister
        // host — NEVER from the upstream-supplied `url` field. Fetching an
        // upstream-controlled URL here would be a server-side request forgery
        // (SSRF) if the registry API ever returned an off-host link. The
        // upstream `url` is still surfaced to the client as `check_url` below
        // (a browser link, not a server fetch), so functionality is preserved.
        let detailed: Record<string, any> | null = null;
        const safeRegCode = /^\d{4,12}$/.test(companies[0].registry_code)
          ? companies[0].registry_code
          : "";
        if (safeRegCode) {
          const companyPageUrl =
            `https://ariregister.rik.ee/est/company/${safeRegCode}`;
          try {
            const pageResponse = await fetch(companyPageUrl);
            if (pageResponse.ok) {
              const html = await pageResponse.text();

              // Helper: extract first regex match group
              const extract = (
                pattern: RegExp,
              ): string => {
                const m = html.match(pattern);
                return m?.[1]
                  ?.replace(/<[^>]+>/g, "")
                  .trim() || "";
              };

              // Capital (e.g. "Osakapital on 31 222 517 €")
              // Note: page may use &nbsp; (\u00a0) between digits
              const capital = extract(
                /[Oo]sakapital\s+on\s+([\d\s\u00a0]+\s*€)/,
              );

              // Registration date
              const registered = extract(
                /Registreeritud[\s\S]*?(\d{2}\.\d{2}\.\d{4})/,
              );

              // Address (full, with zip)
              const addressMatch = html.match(
                /Aadress[\s\S]*?<[^>]*>([^<]{10,120})</,
              );
              const address = addressMatch
                ? addressMatch[1].replace(/<[^>]+>/g, "").trim()
                : companies[0].address || "";

              // Fiscal year period
              const fiscalYear = extract(
                /Majandusaasta periood[\s\S]*?class="[^"]*font-weight-bold[^"]*"[^>]*>([^<]+)/,
              );

              // Activities (EMTAK codes) — match ">62901 - Description<"
              const activityMatches = [
                ...html.matchAll(
                  />(\d{5})\s*[-–—]\s*([^<]{3,120})</g,
                ),
              ];
              const activities = activityMatches
                .slice(0, 5)
                .map((m) => `${m[1]} — ${m[2].trim()}`);

              // Board members — find <tr> rows that contain "Juhatuse liige"
              // and extract the bold person name from each such row.
              const boardMembers: string[] = [];
              const rowMatches = [
                ...html.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/g),
              ];
              for (const rm of rowMatches) {
                const rowHtml = rm[1];
                if (rowHtml.includes("Juhatuse liige")) {
                  // Extract name from bold <td> in this row
                  const nameMatch = rowHtml.match(
                    /font-weight-bold[^>]*>\s*([A-ZÄÖÜÕŠŽ][a-zäöüõšž]+(?:\s+[A-ZÄÖÜÕŠŽ][a-zäöüõšž]+)+)\s*/,
                  );
                  if (nameMatch) {
                    const name = nameMatch[1].trim();
                    if (name && !boardMembers.includes(name)) {
                      boardMembers.push(name);
                    }
                  }
                }
              }

              // Profit (from financial table)
              const profit = extract(
                /Kasum[^<]*<[^>]*>[^<]*<[^>]*>\s*(-?[\d\s]+\d{3})/,
              );

              // Revenue
              const revenue = extract(
                /Müügitulu[^<]*<[^>]*>[^<]*<[^>]*>\s*(-?[\d\s]+\d{3})/,
              );

              // Employees
              const employees = extract(
                /Töötajate arv[^<]*<[^>]*>[^<]*<[^>]*>\s*(\d[\d\s]*)/,
              );

              // Legal form mapping
              const legalFormMap: Record<string, string> = {
                "5": "Osaühing (OÜ)",
                "1": "Aktsiaselts (AS)",
                "4": "Täisühing (TÜ)",
                "6": "Usaldusühing (UÜ)",
                "12": "Mittetulundusühing (MTÜ)",
                "13": "Sihtasutus (SA)",
                "14": "Tulundusühistu",
                "40": "Välismaa äriühingu filiaal",
              };

              detailed = {
                name: companies[0].name,
                registry_code: companies[0].registry_code,
                status: companies[0].status,
                registered: registered || "",
                legal_form:
                  legalFormMap[companies[0].type] ||
                  companies[0].type ||
                  "",
                capital: capital || null,
                address: address || companies[0].address || "",
                activities,
                board_members: boardMembers,
                fiscal_year: fiscalYear || "",
                profit: profit || null,
                revenue: revenue || null,
                employees: employees || null,
                historical_names: companies[0].historical_names || [],
              };
            }
          } catch (_) {
            // HTML scraping failed — continue with basic data
          }
        }

        const checkUrl =
          companies[0].url ||
          `https://ariregister.rik.ee/est/company/${companies[0].registry_code}`;

        return new Response(
          JSON.stringify({
            found: true,
            country: "Estonia",
            companies,
            detailed,
            source: "ariregister.rik.ee",
            check_url: checkUrl,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      return new Response(
        JSON.stringify({
          found: false,
          country: "Estonia",
          message: `Company "${company_name}" not found in Estonian registry`,
          check_url: `https://ariregister.rik.ee/est/company?search_query=${encodeURIComponent(company_name)}`,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Other countries — return links to check manually
    const registryLinks: Record<string, string> = {
      finland: "https://www.prh.fi/en/kaupparekisteri.html",
      fi: "https://www.prh.fi/en/kaupparekisteri.html",
      latvia: "https://www.lursoft.lv",
      lv: "https://www.lursoft.lv",
      lithuania: "https://www.registrucentras.lt",
      lt: "https://www.registrucentras.lt",
      germany: "https://www.handelsregister.de",
      de: "https://www.handelsregister.de",
      sweden: "https://www.bolagsverket.se",
      se: "https://www.bolagsverket.se",
      poland: "https://www.krs-online.com.pl",
      pl: "https://www.krs-online.com.pl",
      spain: "https://www.rmc.es",
      es: "https://www.rmc.es",
    };

    const countryLower = country?.toLowerCase() || "";
    const link = registryLinks[countryLower] || "";

    return new Response(
      JSON.stringify({
        found: false,
        country: country,
        message: `Direct registry lookup not available for ${country}. Check manually.`,
        check_url: link,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    const msg = error instanceof Error ? error.message : "unknown";
    console.error("check-company failed:", msg.slice(0, 200));
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
