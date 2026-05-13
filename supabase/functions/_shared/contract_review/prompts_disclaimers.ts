// prompts_disclaimers.ts — localised regulatory-backstop footer per output
// language. Byte-stable: these strings are pinned by the contract tests.
// -----------------------------------------------------------------------------
// Required by the Estonian Advokatuur and the Finnish Asianajajaliitto:
// Advocat OU provides legal information, not legal advice, and disclaims
// liability for the user's decisions.
// -----------------------------------------------------------------------------

/** Exact footer text per supported user-output language. */
export const kContractReviewDisclaimers: Readonly<Record<string, string>> = {
  et:
    "Informatiivne analüüs, ei asenda advokaadi nõu. " +
    "Advocat OÜ ei vastuta otsuste eest.",
  fi:
    "Informatiivinen analyysi, ei korvaa asianajajan neuvoa. " +
    "Advocat OÜ ei vastaa päätöksistä.",
  en:
    "Informational analysis only — does not replace advice from a " +
    "qualified lawyer. Advocat OÜ accepts no liability for decisions taken.",
  ru:
    "Информационный анализ, не заменяет консультацию адвоката. " +
    "Advocat OÜ не несёт ответственности за принятые решения.",
  de:
    "Informative Analyse — ersetzt keine Rechtsberatung durch einen " +
    "zugelassenen Rechtsanwalt. Advocat OÜ haftet nicht für getroffene " +
    "Entscheidungen.",
  sv:
    "Informativ analys — ersätter inte rådgivning från en advokat. " +
    "Advocat OÜ ansvarar inte för beslut som fattas.",
  fr:
    "Analyse informative — ne remplace pas l'avis d'un avocat. " +
    "Advocat OÜ n'assume aucune responsabilité pour les décisions prises.",
  es:
    "Análisis informativo — no sustituye el consejo de un abogado. " +
    "Advocat OÜ no asume responsabilidad por las decisiones adoptadas.",
  it:
    "Analisi informativa — non sostituisce il parere di un avvocato. " +
    "Advocat OÜ non si assume responsabilità per le decisioni prese.",
  pl:
    "Analiza informacyjna — nie zastępuje porady adwokata. " +
    "Advocat OÜ nie ponosi odpowiedzialności za podjęte decyzje.",
  ar:
    "تحليل معلوماتي فقط — لا يحل محل مشورة محامٍ مؤهل. " +
    "لا تتحمل Advocat OÜ أي مسؤولية عن القرارات المتخذة.",
  tr:
    "Bilgilendirici analiz — bir avukatın tavsiyesinin yerini tutmaz. " +
    "Advocat OÜ alınan kararlardan sorumlu değildir.",
  uk:
    "Інформаційний аналіз, не замінює консультацію адвоката. " +
    "Advocat OÜ не несе відповідальності за прийняті рішення.",
  lv:
    "Informatīva analīze — neaizstāj advokāta konsultāciju. " +
    "Advocat OÜ neuzņemas atbildību par pieņemtajiem lēmumiem.",
  lt:
    "Informacinė analizė — nepakeičia advokato konsultacijos. " +
    "Advocat OÜ neprisiima atsakomybės už priimtus sprendimus.",
  ro:
    "Analiză informativă — nu înlocuiește consultanța unui avocat. " +
    "Advocat OÜ nu își asumă responsabilitatea pentru deciziile luate.",
  fa:
    "تحلیل اطلاع‌رسانی — جایگزین مشاوره وکیل نیست. " +
    "Advocat OÜ مسئولیتی در قبال تصمیمات گرفته‌شده ندارد.",
};

/** Returns the disclaimer for [lang], falling back to English. */
export function disclaimerFor(lang: string): string {
  return kContractReviewDisclaimers[lang] ?? kContractReviewDisclaimers["en"];
}
