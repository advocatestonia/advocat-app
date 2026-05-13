// prompts_email.ts — Instructions for generating the email_to_counterparty
// field. The email is ALWAYS written in the contract's original language so
// the user can forward the draft without translating.
//
// This is the killer feature of Contract Review: collapses 4 billable hours
// of bilingual drafting into 90 seconds.
// -----------------------------------------------------------------------------

/** Returns the email-draft addendum bound to [originalLanguage]. */
export function buildEmailDraftAddendum(originalLanguage: string): string {
  const trimmed = originalLanguage.trim();
  const lang = trimmed.length === 0 ? "en" : trimmed;
  const greetings = greetingHintFor(lang);
  const subjectWord = subjectWordFor(lang);
  const signaturePlaceholder = signaturePlaceholderFor(lang);
  const closingFormula = closingFormulaFor(lang);
  const deadlinePhrase = deadlinePhraseFor(lang);
  return `# EMAIL DRAFT — ADDENDUM (killer feature)

The \`email_to_counterparty\` field is the message the user will (after
review) send back to the counterparty. CRITICAL rules:

1. **Language**: the email is written in the contract's ORIGINAL
   language, which the orchestrator has detected as **${lang}**.
   Do NOT translate it into the user's reading language. A contract
   in German gets a German email; a contract in English gets an
   English email; a Finnish contract gets a Finnish email. The whole
   body — subject, greeting, opener, numbered questions, closing,
   signature placeholder — must be in \`${lang}\`. Mark
   \`email_to_counterparty.language\` with the same code.

2. **Subject line**: short, factual, mentions the contract name and the
   word "${subjectWord}" or its closest equivalent in \`${lang}\`. Example
   pattern: "\`<Contract name>\` — ${subjectWord}". Do NOT use generic
   subjects like "Hello" or "Contract" or "Re:".

3. **Greeting**: open with a register appropriate to business
   correspondence in \`${lang}\`. Suggested forms: ${greetings}. If the
   counterparty contact is unknown, use the polite plural form for that
   language. Never use "Dear Sir/Madam" verbatim.

4. **Register**: senior-associate professional. No "I hope this email
   finds you well." Open with one line stating the purpose, ask the
   questions, close with a single courteous sign-off.

5. **Substance — 3 to 5 numbered, clause-specific questions** drawn
   from your analysis. Each question MUST:
   - Reference a clause number (e.g. "§9.2", "Clause 14.3", "Anhang B",
     "kohta 7.3", "punkt 12", "пункт 5").
   - Be phrased as a REQUEST, not a demand. Use modal verbs and the
     conditional in the local language ("könnten Sie", "could you",
     "voisitteko", "czy mogliby Państwo", "pourriez-vous",
     "не могли бы вы").
   - Ask a single, answerable question. No compound questions.
   - Be neutral in tone: "could you clarify", "we would appreciate
     confirmation", "please advise on the rationale for".
   - **FORBIDDEN loaded words** in any language form: "unfair",
     "unacceptable", "predatory", "exploit", "abusive", "ungerecht",
     "unannehmbar", "kohtuuton", "epäreilu", "несправедл-", "хищническ-",
     "drapieżny", "niesprawiedliwy", "injuste", "inacceptable",
     "injusto", "inaceptable", "inaccettabile". Phrase the same idea as
     a neutral request for clarification of rationale or scope.

6. **Optional response deadline**: end the questions block with a line
   inviting a response within 1–2 weeks (${deadlinePhrase}) — never less
   than 7 calendar days.

7. **Do not propose redline language in this email.** Redlines go in
   the user's separate negotiation pack; this email is the opener. Its
   job is to surface ambiguities and force the counterparty to commit.

8. **Sign-off**: leave the actual signature line as
   \`${signaturePlaceholder}\` — the user fills it in. The closing
   formula must match \`${lang}\` business conventions (${closingFormula}).

The body should sit comfortably in **120–280 words**. Longer than that
and the counterparty's lawyer will skim and miss things. Format as
markdown: \`**Subject:** …\` on the first line, blank line, greeting,
blank line, one-sentence opener, numbered questions, blank line, closing
formula, signature placeholder.`;
}

/** Greeting hints by language. */
export function greetingHintFor(lang: string): string {
  switch (lang) {
    case "de":
      return "\"Sehr geehrte Damen und Herren\" / \"Sehr geehrter Herr X\" / \"Sehr geehrte Frau Y\"";
    case "fi":
      return "\"Hyvä vastaanottaja\" / \"Arvoisa X\" / \"Hyvä X\"";
    case "et":
      return "\"Lugupeetud X\" / \"Tere\" (informaalsem)";
    case "ru":
      return "\"Уважаемый г-н X\" / \"Уважаемая г-жа Y\" / \"Уважаемые коллеги\"";
    case "pl":
      return "\"Szanowny Panie\" / \"Szanowna Pani\" / \"Szanowni Państwo\"";
    case "fr":
      return "\"Madame, Monsieur\" / \"Cher Monsieur X\" / \"Chère Madame Y\"";
    case "es":
      return "\"Estimado Sr. X\" / \"Estimada Sra. Y\" / \"Estimados señores\"";
    case "it":
      return "\"Egregio Signor X\" / \"Gentile Signora Y\" / \"Spettabile X\"";
    case "sv":
      return "\"Bästa X\" / \"Hej X\" (informaalsem)";
    case "no":
      return "\"Kjære X\" / \"Hei X\"";
    case "da":
      return "\"Kære X\" / \"Hej X\"";
    case "uk":
      return "\"Шановний пане X\" / \"Шановна пані Y\"";
    case "lv":
      return "\"Cienījamais X kungs\" / \"Cienījamā Y kundze\"";
    case "lt":
      return "\"Gerbiamasis X\" / \"Gerbiamoji Y\"";
    case "en":
    default:
      return "\"Dear Mr/Ms X\" / \"Dear <Counterparty> team\"";
  }
}

/** Localised word for "Questions" / "Inquiry" used in the subject line. */
export function subjectWordFor(lang: string): string {
  switch (lang) {
    case "de":
      return "Fragen";
    case "fi":
      return "Kysymyksiä";
    case "et":
      return "Küsimused";
    case "ru":
      return "Вопросы";
    case "pl":
      return "Pytania";
    case "fr":
      return "Questions";
    case "es":
      return "Consultas";
    case "it":
      return "Domande";
    case "sv":
      return "Frågor";
    case "no":
      return "Spørsmål";
    case "da":
      return "Spørgsmål";
    case "uk":
      return "Питання";
    case "lv":
      return "Jautājumi";
    case "lt":
      return "Klausimai";
    case "en":
    default:
      return "Questions";
  }
}

/** Localised signature placeholder kept in [brackets] for the user to fill. */
export function signaturePlaceholderFor(lang: string): string {
  switch (lang) {
    case "de":
      return "[Unterschrift]";
    case "fi":
      return "[Allekirjoitus]";
    case "et":
      return "[Allkiri]";
    case "ru":
      return "[Подпись]";
    case "pl":
      return "[Podpis]";
    case "fr":
      return "[Signature]";
    case "es":
      return "[Firma]";
    case "it":
      return "[Firma]";
    case "sv":
      return "[Signatur]";
    case "no":
      return "[Signatur]";
    case "da":
      return "[Underskrift]";
    case "uk":
      return "[Підпис]";
    case "lv":
      return "[Paraksts]";
    case "lt":
      return "[Parašas]";
    case "en":
    default:
      return "[Name]";
  }
}

/** Localised business closing formula examples. */
export function closingFormulaFor(lang: string): string {
  switch (lang) {
    case "de":
      return "\"Mit freundlichen Grüßen\"";
    case "fi":
      return "\"Ystävällisin terveisin\"";
    case "et":
      return "\"Lugupidamisega\"";
    case "ru":
      return "\"С уважением\"";
    case "pl":
      return "\"Z poważaniem\"";
    case "fr":
      return "\"Cordialement\" / \"Bien cordialement\"";
    case "es":
      return "\"Atentamente\" / \"Saludos cordiales\"";
    case "it":
      return "\"Distinti saluti\" / \"Cordiali saluti\"";
    case "sv":
      return "\"Med vänliga hälsningar\"";
    case "no":
      return "\"Med vennlig hilsen\"";
    case "da":
      return "\"Med venlig hilsen\"";
    case "uk":
      return "\"З повагою\"";
    case "lv":
      return "\"Ar cieņu\"";
    case "lt":
      return "\"Pagarbiai\"";
    case "en":
    default:
      return "\"Kind regards\" / \"Best regards\"";
  }
}

/** Localised "within the next 14 days" phrasing examples. */
export function deadlinePhraseFor(lang: string): string {
  switch (lang) {
    case "de":
      return "\"innerhalb der nächsten 14 Tage\" / \"binnen zwei Wochen\"";
    case "fi":
      return "\"kahden viikon kuluessa\"";
    case "et":
      return "\"kahe nädala jooksul\"";
    case "ru":
      return "\"в течение двух недель\"";
    case "pl":
      return "\"w ciągu dwóch tygodni\"";
    case "fr":
      return "\"dans un délai de deux semaines\"";
    case "es":
      return "\"en un plazo de dos semanas\"";
    case "it":
      return "\"entro due settimane\"";
    case "sv":
      return "\"inom två veckor\"";
    case "no":
      return "\"innen to uker\"";
    case "da":
      return "\"inden for to uger\"";
    case "uk":
      return "\"протягом двох тижнів\"";
    case "lv":
      return "\"divu nedēļu laikā\"";
    case "lt":
      return "\"per dvi savaites\"";
    case "en":
    default:
      return "\"within the next two weeks\" / \"at your earliest convenience\"";
  }
}
