# SEO Setup Checklist

Created: 2026-05-11
Owner action items: 5 manual tasks (~45 min total)

Context: technical SEO already applied in code (Schema.org JSON-LD,
sitemap, robots.txt, hreflang, OG/Twitter cards, GA4 consent-gated).
Below are the platform registrations only an owner can do.

---

## ACTION NEEDED — owner does these manually (45 min total):

### 1. Google Search Console (15 min)
- Go to https://search.google.com/search-console
- Add property: `advocat.ee`
- Verify via HTML tag — paste the meta tag into the placeholder at the
  top of `web/index.html`:
  ```html
  <meta name="google-site-verification" content="YOUR_VERIFICATION_CODE">
  ```
- Submit sitemap: `https://advocat.ee/sitemap.xml`

### 2. Bing Webmaster Tools (10 min)
- https://www.bing.com/webmasters
- Same procedure — paste verification into placeholder in
  `web/index.html`:
  ```html
  <meta name="msvalidate.01" content="YOUR_VERIFICATION_CODE">
  ```
- Submit sitemap: `https://advocat.ee/sitemap.xml`

### 3. Google Business Profile (15 min)
- https://www.google.com/business/
- Register Vorantis OÜ
- Add Tallinn office address (Tornimäe tn 5, 15010 Tallinn)
- Categories: "Legal services", "Software company"
- Add photos, hours, link to advocat.ee

### 4. Estonian business directories (5 min each)
- Inforegister.ee (free)
- Krediidiinfo.ee (free)

### 5. Verify structured data
- Test with https://search.google.com/test/rich-results
- Paste https://advocat.ee — should show Organization +
  WebApplication + LegalService
- Test a FAQ page (e.g. https://advocat.ee/blog/en/faq-legal-help-estonia.html)
  — should show FAQPage with all questions parsed

---

## What was applied in code (2026-05-11)

- `web/index.html` head:
  - 3 JSON-LD blocks: Organization, WebApplication, LegalService
  - Action-oriented meta description ("Get instant legal answers ... 24/7")
  - Placeholders for GSC + Bing verification meta tags
- `web/sitemap.xml`:
  - `<lastmod>` bumped to 2026-05-11 across all 37 URLs
  - Confirmed: /, /app.html, /blog/, /lawyers.html, /terms.html,
    /privacy.html all present
- FAQ pages (already had FAQPage schema, no change needed):
  - `web/blog/en/faq-legal-help-estonia.html`
  - `web/blog/kkk-oigusabi.html`
  - `web/blog/ru/chasto-zadavaemye-voprosy.html`

## Not deployed yet
Owner ships via canary-deploy.sh when ready.
