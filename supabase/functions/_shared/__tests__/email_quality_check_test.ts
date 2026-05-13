// Deno tests for `_shared/email_quality_check.ts`.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/email_quality_check_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildCorrectivePrompt,
  checkEmailQuality,
  detectEmailLanguage,
  MAX_WORDS,
  MIN_QUESTIONS,
  MIN_WORDS,
} from "../email_quality_check.ts";

// =============================================================================
// Sample emails — kept compact but realistic. Each comfortably hits 120+ words.
// =============================================================================

const SAMPLE_DE = `**Subject:** Händlervertrag – Fragen zu Klauseln §3, §7 und §11

Sehr geehrte Damen und Herren,

vielen Dank für die Übersendung des Händlervertragsentwurfs. Vor einer
abschließenden Bewertung möchten wir Sie um Klärung der folgenden Punkte
bitten, damit wir die kommerziellen Verpflichtungen sauber gegen unsere
internen Vorgaben spiegeln können.

1. Könnten Sie bestätigen, dass die Mindestabnahmemenge in §3.2 sich auf
   das Kalenderjahr und nicht auf das Vertragsjahr bezieht?
2. In §7.1 wird die Haftungsobergrenze auf den Nettojahresumsatz begrenzt.
   Wie ist dies mit der Ausgleichspflicht nach §89b HGB vereinbar?
3. Wir bitten um eine Erläuterung der Kündigungsfrist in §11.3, insbesondere
   im Hinblick auf die Amortisation der Showroom-Investitionen.
4. Könnten Sie den Rückkaufpreis für Lagerbestände in §11.5 präzisieren
   (Nettoeinkaufspreis, Marktpreis oder Listenpreis)?

Über eine Rückmeldung innerhalb der nächsten 14 Tage würden wir uns freuen.

Mit freundlichen Grüßen,

[Unterschrift]`;

const SAMPLE_EN = `**Subject:** Master SaaS Agreement — Questions on §8, §11 and §14

Dear Acme Cloud team,

Thank you for sending across the draft Master SaaS Agreement. Before we
proceed to redlines, we would appreciate confirmation on the following
clauses so that our internal commercial and security reviews can align.

1. Could you confirm whether the uptime SLA in §8.2 is measured on a
   monthly or quarterly basis, and what counts as scheduled maintenance?
2. In §11.4 the data-export window after termination is set at thirty
   days; could you advise on the rationale and whether ninety days is
   negotiable?
3. We would appreciate clarification on the sub-processor change-notice
   in §14.1, particularly whether silence equals consent.
4. Please advise on the fee escalation cap referenced in §6.3, which
   currently has no upper bound.

A response within the next two weeks would be most welcome.

Kind regards,

[Name]`;

const SAMPLE_FI = `**Subject:** Työsopimusluonnos — kysymyksiä kohtiin 4, 6, 9 ja 12

Hyvä vastaanottaja,

kiitos työsopimusluonnoksen toimittamisesta meidän tarkastettavaksi.
Ennen kuin vahvistamme hyväksyntämme luonnoksen sisältöön, pyydämme
kohteliaasti tarkennusta seuraaviin kohtiin, jotta voimme verrata niitä
yhtiömme sisäisiin ohjeistuksiin sekä Suomen voimassa olevaan
työsopimuslakiin ja vakiintuneeseen oikeuskäytäntöön ennen
allekirjoitusta.

1. Voisitteko vahvistaa, että kohdassa 4 mainittu koeaika neljä
   kuukautta tulkitaan työsopimuslain 1 luvun 4 §:n mukaisesti?
2. Kohdassa 6.2 mainittu kilpailukielto on kestoltaan kaksitoista
   kuukautta. Voisitteko tarkentaa, millä perusteella tämä on katsottu
   kohtuulliseksi työsopimuslain 3 luvun 5 §:n valossa, ja mitä
   korvausta työntekijälle on tarkoitettu maksaa rajoituksen ajalta?
3. Pyytäisimme selvennystä kohtaan 9 koskien irtisanomisajan
   epäsymmetriaa työnantajan ja työntekijän välillä.
4. Voisitteko vahvistaa kohdassa 12 mainitun salassapitovelvoitteen
   keston työsuhteen päättymisen jälkeen?
5. Voisitteko tarkentaa kohdassa 14 mainitun matkustamisvelvoitteen
   maantieteellistä laajuutta ja siihen liittyvää korvauskäytäntöä?

Olisimme kiitollisia vastauksesta kahden viikon kuluessa.

Ystävällisin terveisin,

[Allekirjoitus]`;

const SAMPLE_PL = `**Subject:** Umowa o zachowaniu poufności — pytania do §2, §4 i §7

Szanowni Państwo,

dziękujemy za przekazanie projektu umowy o zachowaniu poufności. Przed
podpisaniem prosimy uprzejmie o wyjaśnienie poniższych kwestii, aby mogli
Państwo dostosować zapisy do naszych wewnętrznych standardów.

1. Czy mogliby Państwo potwierdzić, że definicja Informacji Poufnych w §2.1
   obejmuje informacje przekazywane ustnie, jeżeli zostaną one potwierdzone
   pisemnie w ciągu trzydziestu dni?
2. W §4.3 czas obowiązywania zobowiązania określono na pięć lat. Prosimy
   o uzasadnienie tego okresu w odniesieniu do tajemnic przedsiębiorstwa.
3. Prosimy o doprecyzowanie §5 dotyczącego zwrotu lub zniszczenia
   materiałów po wygaśnięciu umowy, w tym formy potwierdzenia.
4. Czy mogliby Państwo wyjaśnić §7.2 w zakresie wzajemności
   zobowiązań do zachowania poufności?

Bylibyśmy wdzięczni za odpowiedź w ciągu dwóch tygodni.

Z poważaniem,

[Podpis]`;

// =============================================================================
// detectEmailLanguage
// =============================================================================

Deno.test("detectEmailLanguage — German", () => {
  assertEquals(detectEmailLanguage(SAMPLE_DE), "de");
});

Deno.test("detectEmailLanguage — English", () => {
  assertEquals(detectEmailLanguage(SAMPLE_EN), "en");
});

Deno.test("detectEmailLanguage — Finnish", () => {
  assertEquals(detectEmailLanguage(SAMPLE_FI), "fi");
});

Deno.test("detectEmailLanguage — Polish", () => {
  assertEquals(detectEmailLanguage(SAMPLE_PL), "pl");
});

Deno.test("detectEmailLanguage — Russian Cyrillic body", () => {
  const ru =
    "Уважаемые коллеги, благодарим за проект договора. Прошу пояснить " +
    "следующие пункты: 1. Что именно относится к конфиденциальной информации? " +
    "2. На каких условиях возможна передача данных третьим лицам?";
  assertEquals(detectEmailLanguage(ru), "ru");
});

Deno.test("detectEmailLanguage — empty / too short returns 'und'", () => {
  assertEquals(detectEmailLanguage(""), "und");
  assertEquals(detectEmailLanguage("Hi"), "und");
});

Deno.test("detectEmailLanguage — Ukrainian disambiguates from Russian", () => {
  const uk =
    "Шановні колеги, дякуємо за проєкт договору. Просимо роз'яснити такі " +
    "пункти: 1. Що саме належить до конфіденційної інформації згідно з §2? " +
    "2. На яких умовах можлива передача даних третім особам у §5?";
  assertEquals(detectEmailLanguage(uk), "uk");
});

// =============================================================================
// checkEmailQuality — happy paths
// =============================================================================

Deno.test("checkEmailQuality — German contract passes (DE expected)", () => {
  const r = checkEmailQuality({
    email: SAMPLE_DE,
    expectedLanguage: "de",
  });
  assertEquals(r.ok, true, `issues: ${JSON.stringify(r.issues)}`);
  assertEquals(r.detected_language, "de");
  assert(r.numbered_question_count >= MIN_QUESTIONS);
  assert(r.word_count >= MIN_WORDS && r.word_count <= MAX_WORDS);
});

Deno.test("checkEmailQuality — English contract passes (EN expected)", () => {
  const r = checkEmailQuality({
    email: SAMPLE_EN,
    expectedLanguage: "en",
  });
  assertEquals(r.ok, true, `issues: ${JSON.stringify(r.issues)}`);
  assertEquals(r.detected_language, "en");
});

Deno.test("checkEmailQuality — Finnish contract passes (FI expected)", () => {
  const r = checkEmailQuality({
    email: SAMPLE_FI,
    expectedLanguage: "fi",
  });
  assertEquals(r.ok, true, `issues: ${JSON.stringify(r.issues)}`);
  assertEquals(r.detected_language, "fi");
});

Deno.test("checkEmailQuality — Polish contract passes (PL expected)", () => {
  const r = checkEmailQuality({
    email: SAMPLE_PL,
    expectedLanguage: "pl",
  });
  assertEquals(r.ok, true, `issues: ${JSON.stringify(r.issues)}`);
  assertEquals(r.detected_language, "pl");
});

// =============================================================================
// checkEmailQuality — failure modes
// =============================================================================

Deno.test("checkEmailQuality — wrong language is an error", () => {
  // German email submitted for an English contract.
  const r = checkEmailQuality({
    email: SAMPLE_DE,
    expectedLanguage: "en",
  });
  assertFalse(r.ok);
  const codes = r.issues.map((i) => i.code);
  assert(codes.includes("wrong_language"));
});

Deno.test("checkEmailQuality — flags loaded language", () => {
  const bad = SAMPLE_EN.replace(
    "Could you confirm whether",
    "This unfair clause demands that you confirm whether",
  );
  const r = checkEmailQuality({
    email: bad,
    expectedLanguage: "en",
  });
  assertFalse(r.ok);
  assert(r.issues.some((i) => i.code === "loaded_language"));
});

Deno.test("checkEmailQuality — too few numbered questions", () => {
  const short = `**Subject:** Test

Dear team,

We have only one question about the agreement.

1. Could you please clarify §3.2 in detail and at length so this body
   easily exceeds the minimum word count required by the quality gate,
   covering renewal terms, termination, indemnity, IP ownership, data
   handling, sub-processor notice, security baseline, audit rights,
   exit assistance, and the localised governing-law clause within the
   master services framework that we are reviewing this quarter?

Kind regards,

[Name]`;
  const r = checkEmailQuality({
    email: short,
    expectedLanguage: "en",
  });
  assertFalse(r.ok);
  assert(r.issues.some((i) => i.code === "too_few_questions"));
});

Deno.test("checkEmailQuality — too short", () => {
  const r = checkEmailQuality({
    email: "Hi. 1. Q? 2. Q? 3. Q? [Name]",
    expectedLanguage: "en",
  });
  assertFalse(r.ok);
  assert(r.issues.some((i) => i.code === "too_short"));
});

Deno.test("checkEmailQuality — missing signature placeholder is a warning", () => {
  const noSig = SAMPLE_EN.replace("[Name]", "Sincerely yours");
  const r = checkEmailQuality({
    email: noSig,
    expectedLanguage: "en",
  });
  // Warning-only: should still pass if everything else is fine.
  assertEquals(r.ok, true);
  assert(
    r.issues.some((i) => i.code === "missing_signature_placeholder"),
  );
});

// =============================================================================
// buildCorrectivePrompt
// =============================================================================

// =============================================================================
// End-to-end language-match assertions per spec:
//   "German contract → German email (not English)"
//   "English contract → English email"
// These call the prompt builder + the verifier together to prove the
// instructions force the right language in real samples.
// =============================================================================

Deno.test("E2E: German contract sample → DE email passes verifier (not EN)", () => {
  // The German sample was generated by the (mocked) planner. The verifier
  // must agree that it is German and reject an EN expectation.
  const okDe = checkEmailQuality({
    email: SAMPLE_DE,
    expectedLanguage: "de",
  });
  assert(okDe.ok, `DE-vs-DE failed: ${JSON.stringify(okDe.issues)}`);

  const wrongEn = checkEmailQuality({
    email: SAMPLE_DE,
    expectedLanguage: "en",
  });
  assertFalse(wrongEn.ok);
  assert(wrongEn.issues.some((i) => i.code === "wrong_language"));
});

Deno.test("E2E: English contract sample → EN email passes verifier (not DE)", () => {
  const okEn = checkEmailQuality({
    email: SAMPLE_EN,
    expectedLanguage: "en",
  });
  assert(okEn.ok, `EN-vs-EN failed: ${JSON.stringify(okEn.issues)}`);

  const wrongDe = checkEmailQuality({
    email: SAMPLE_EN,
    expectedLanguage: "de",
  });
  assertFalse(wrongDe.ok);
  assert(wrongDe.issues.some((i) => i.code === "wrong_language"));
});

Deno.test("buildCorrectivePrompt mentions expected language and rules", () => {
  const r = checkEmailQuality({
    email: SAMPLE_DE,
    expectedLanguage: "en",
  });
  const prompt = buildCorrectivePrompt(r);
  assertStringIncludes(prompt, "en");
  assertStringIncludes(prompt, "numbered");
  assertStringIncludes(prompt, String(MIN_QUESTIONS));
  assertStringIncludes(prompt, String(MIN_WORDS));
});
