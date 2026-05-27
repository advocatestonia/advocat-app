// drafting/widgets/drafting_strings.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Lightweight locale-aware string table for the Drafting Studio. Lives next
// to the widgets so we don't have to run flutter_gen_l10n for every minor
// MVP iteration (and so widget tests don't have to bootstrap the global
// AppLocalizations delegate).
//
// Translations cover the four product-priority languages (et, fi, en, ru);
// every other locale falls through to English. The keys are intentionally
// scoped with `drafting*` so they can be ported into the global ARB system
// in a single sweep when the studio leaves MVP.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class _Strings {
  const _Strings({
    required this.title,
    required this.empty,
    required this.placeholder,
    required this.draftsList,
    required this.save,
    required this.saved,
    required this.savedJustNow,
    required this.aiRevise,
    required this.exportPdf,
    required this.exportDocx,
    required this.exportMd,
    required this.deleteDraft,
    required this.confirmDelete,
    required this.confirmDeleteMessage,
    required this.confirm,
    required this.cancel,
    required this.draftReplyTo,
    required this.untitled,
    required this.titleHint,
    required this.aiReviseTitle,
    required this.aiReviseSelectionLabel,
    required this.aiReviseInstructionLabel,
    required this.aiReviseInstructionHint,
    required this.aiReviseRunButton,
    required this.aiReviseSuggestionLabel,
    required this.aiReviseChangesLabel,
    required this.aiReviseAccept,
    required this.aiReviseReject,
    required this.formatBold,
    required this.formatItalic,
    required this.formatHeading,
    required this.formatBullet,
    required this.formatNumbered,
    required this.emptyListMessage,
    required this.emptyListAction,
    required this.exporting,
    required this.exportFailed,
    required this.saveFailed,
    required this.newDraft,
    // Templates picker
    required this.templatesTitle,
    required this.templatesSubtitle,
    required this.templateBlankTitle,
    required this.templateBlankDescription,
    required this.templateLetterTitle,
    required this.templateLetterDescription,
    required this.templateAppealTitle,
    required this.templateAppealDescription,
    required this.templateMemoTitle,
    required this.templateMemoDescription,
    required this.templateContractReplyTitle,
    required this.templateContractReplyDescription,
    required this.templateContractReplyLocked,
    required this.templateStarterTitleBlank,
    required this.templateStarterTitleLetter,
    required this.templateStarterTitleAppeal,
    required this.templateStarterTitleMemo,
    required this.templateStarterTitleContractReply,
    required this.templateStarterBodyBlank,
    required this.templateStarterBodyLetter,
    required this.templateStarterBodyAppeal,
    required this.templateStarterBodyMemo,
    required this.templateStarterBodyContractReply,
    // Version history
    required this.versionsTitle,
    required this.versionsEmpty,
    required this.versionsAiBadge,
    required this.versionsRestoreAction,
    required this.versionsRestoreConfirmTitle,
    required this.versionsRestoreConfirmMessage,
    required this.versionsRestoreConfirmAction,
    required this.versionsRestoreSuccess,
    required this.versionsRestoreFailed,
    required this.versionHistory,
    // Track 1A — Save to Vault + PDF worker fallback message
    required this.saveToVault,
    required this.savedToVault,
    required this.pdfWorkerUnavailable,
    // Drafting × Vault bridge (2026-05-27)
    required this.savingToVault,
    required this.saveToVaultFailed,
    required this.openInVault,
    required this.vaultNoteChip,
    required this.vaultNoteTitlePrefix,
    required this.editInStudio,
  });

  final String title;
  final String empty;
  final String placeholder;
  final String draftsList;
  final String save;
  final String saved;
  final String savedJustNow;
  final String aiRevise;
  final String exportPdf;
  final String exportDocx;
  final String exportMd;
  final String deleteDraft;
  final String confirmDelete;
  final String confirmDeleteMessage;
  final String confirm;
  final String cancel;
  final String draftReplyTo;
  final String untitled;
  final String titleHint;
  final String aiReviseTitle;
  final String aiReviseSelectionLabel;
  final String aiReviseInstructionLabel;
  final String aiReviseInstructionHint;
  final String aiReviseRunButton;
  final String aiReviseSuggestionLabel;
  final String aiReviseChangesLabel;
  final String aiReviseAccept;
  final String aiReviseReject;
  final String formatBold;
  final String formatItalic;
  final String formatHeading;
  final String formatBullet;
  final String formatNumbered;
  final String emptyListMessage;
  final String emptyListAction;
  final String exporting;
  final String exportFailed;
  final String saveFailed;
  final String newDraft;
  // Templates picker
  final String templatesTitle;
  final String templatesSubtitle;
  final String templateBlankTitle;
  final String templateBlankDescription;
  final String templateLetterTitle;
  final String templateLetterDescription;
  final String templateAppealTitle;
  final String templateAppealDescription;
  final String templateMemoTitle;
  final String templateMemoDescription;
  final String templateContractReplyTitle;
  final String templateContractReplyDescription;
  final String templateContractReplyLocked;
  final String templateStarterTitleBlank;
  final String templateStarterTitleLetter;
  final String templateStarterTitleAppeal;
  final String templateStarterTitleMemo;
  final String templateStarterTitleContractReply;
  final String templateStarterBodyBlank;
  final String templateStarterBodyLetter;
  final String templateStarterBodyAppeal;
  final String templateStarterBodyMemo;
  final String templateStarterBodyContractReply;
  // Version history
  final String versionsTitle;
  final String versionsEmpty;
  final String versionsAiBadge;
  final String versionsRestoreAction;
  final String versionsRestoreConfirmTitle;
  final String versionsRestoreConfirmMessage;
  final String versionsRestoreConfirmAction;
  final String versionsRestoreSuccess;
  final String versionsRestoreFailed;
  final String versionHistory;
  // Track 1A
  final String saveToVault;
  final String savedToVault;
  final String pdfWorkerUnavailable;
  // Drafting × Vault bridge (2026-05-27)
  final String savingToVault;
  final String saveToVaultFailed;
  final String openInVault;
  final String vaultNoteChip;
  final String vaultNoteTitlePrefix;
  final String editInStudio;
}

/// Public façade used by Drafting Studio widgets.
class DraftingStrings {
  const DraftingStrings._(this._s);
  final _Strings _s;

  String get title => _s.title;
  String get empty => _s.empty;
  String get placeholder => _s.placeholder;
  String get draftsList => _s.draftsList;
  String get save => _s.save;
  String get saved => _s.saved;
  String get savedJustNow => _s.savedJustNow;
  String get aiRevise => _s.aiRevise;
  String get exportPdf => _s.exportPdf;
  String get exportDocx => _s.exportDocx;
  String get exportMd => _s.exportMd;
  String get deleteDraft => _s.deleteDraft;
  String get confirmDelete => _s.confirmDelete;
  String get confirmDeleteMessage => _s.confirmDeleteMessage;
  String get confirm => _s.confirm;
  String get cancel => _s.cancel;
  String draftReplyTo(String counterparty) =>
      _s.draftReplyTo.replaceAll('{name}', counterparty);
  String get untitled => _s.untitled;
  String get titleHint => _s.titleHint;
  String get draftingAiReviseTitle => _s.aiReviseTitle;
  String get draftingAiReviseSelectionLabel => _s.aiReviseSelectionLabel;
  String get draftingAiReviseInstructionLabel => _s.aiReviseInstructionLabel;
  String get draftingAiReviseInstructionHint => _s.aiReviseInstructionHint;
  String get draftingAiReviseRunButton => _s.aiReviseRunButton;
  String get draftingAiReviseSuggestionLabel => _s.aiReviseSuggestionLabel;
  String get draftingAiReviseChangesLabel => _s.aiReviseChangesLabel;
  String get draftingAiReviseAccept => _s.aiReviseAccept;
  String get draftingAiReviseReject => _s.aiReviseReject;
  String get formatBold => _s.formatBold;
  String get formatItalic => _s.formatItalic;
  String get formatHeading => _s.formatHeading;
  String get formatBullet => _s.formatBullet;
  String get formatNumbered => _s.formatNumbered;
  String get emptyListMessage => _s.emptyListMessage;
  String get emptyListAction => _s.emptyListAction;
  String get exporting => _s.exporting;
  String get exportFailed => _s.exportFailed;
  String get saveFailed => _s.saveFailed;
  String get newDraft => _s.newDraft;

  // Templates picker
  String get templatesTitle => _s.templatesTitle;
  String get templatesSubtitle => _s.templatesSubtitle;
  String get templateBlankTitle => _s.templateBlankTitle;
  String get templateBlankDescription => _s.templateBlankDescription;
  String get templateLetterTitle => _s.templateLetterTitle;
  String get templateLetterDescription => _s.templateLetterDescription;
  String get templateAppealTitle => _s.templateAppealTitle;
  String get templateAppealDescription => _s.templateAppealDescription;
  String get templateMemoTitle => _s.templateMemoTitle;
  String get templateMemoDescription => _s.templateMemoDescription;
  String get templateContractReplyTitle => _s.templateContractReplyTitle;
  String get templateContractReplyDescription =>
      _s.templateContractReplyDescription;
  String get templateContractReplyLocked => _s.templateContractReplyLocked;
  String get templateStarterTitleBlank => _s.templateStarterTitleBlank;
  String get templateStarterTitleLetter => _s.templateStarterTitleLetter;
  String get templateStarterTitleAppeal => _s.templateStarterTitleAppeal;
  String get templateStarterTitleMemo => _s.templateStarterTitleMemo;
  String get templateStarterTitleContractReply =>
      _s.templateStarterTitleContractReply;
  String get templateStarterBodyBlank => _s.templateStarterBodyBlank;
  String get templateStarterBodyLetter => _s.templateStarterBodyLetter;
  String get templateStarterBodyAppeal => _s.templateStarterBodyAppeal;
  String get templateStarterBodyMemo => _s.templateStarterBodyMemo;
  String get templateStarterBodyContractReply =>
      _s.templateStarterBodyContractReply;

  // Version history
  String get versionsTitle => _s.versionsTitle;
  String get versionsEmpty => _s.versionsEmpty;
  String get versionsAiBadge => _s.versionsAiBadge;
  String get versionsRestoreAction => _s.versionsRestoreAction;
  String get versionsRestoreConfirmTitle => _s.versionsRestoreConfirmTitle;
  String get versionsRestoreConfirmMessage =>
      _s.versionsRestoreConfirmMessage;
  String get versionsRestoreConfirmAction => _s.versionsRestoreConfirmAction;
  String get versionsRestoreSuccess => _s.versionsRestoreSuccess;
  String get versionsRestoreFailed => _s.versionsRestoreFailed;
  String get versionHistory => _s.versionHistory;

  // Track 1A — Save to Vault + PDF worker fallback message
  String get saveToVault => _s.saveToVault;
  String get savedToVault => _s.savedToVault;
  String get pdfWorkerUnavailable => _s.pdfWorkerUnavailable;

  // Drafting × Vault bridge (2026-05-27)
  String get savingToVault => _s.savingToVault;
  String get saveToVaultFailed => _s.saveToVaultFailed;
  String get openInVault => _s.openInVault;
  String get vaultNoteChip => _s.vaultNoteChip;
  String get vaultNoteTitlePrefix => _s.vaultNoteTitlePrefix;
  String get editInStudio => _s.editInStudio;

  /// Returns the matching string table for the active locale. Falls back to
  /// English for any locale we don't ship a translation for yet.
  static DraftingStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return DraftingStrings._(_tables[code] ?? _tables['en']!);
  }

  /// Test hook — construct directly for a known locale.
  // ignore: library_private_types_in_public_api
  static DraftingStrings forCode(String code) =>
      DraftingStrings._(_tables[code] ?? _tables['en']!);
}

final Map<String, _Strings> _tables = <String, _Strings>{
  'en': const _Strings(
    title: 'Drafting Studio',
    empty: 'Empty draft',
    placeholder: 'Start typing your draft…',
    draftsList: 'My drafts',
    save: 'Save',
    saved: 'Saved',
    savedJustNow: 'Saved just now',
    aiRevise: 'Revise with AI',
    exportPdf: 'Export PDF',
    exportDocx: 'Export DOCX',
    exportMd: 'Export Markdown',
    deleteDraft: 'Delete draft',
    confirmDelete: 'Delete this draft?',
    confirmDeleteMessage: 'This action cannot be undone.',
    confirm: 'Delete',
    cancel: 'Cancel',
    draftReplyTo: 'Reply to {name}',
    untitled: 'Untitled',
    titleHint: 'Title (optional)',
    aiReviseTitle: 'Revise with AI',
    aiReviseSelectionLabel: 'Selected text:',
    aiReviseInstructionLabel: 'Instruction (optional)',
    aiReviseInstructionHint: 'e.g. "make it more formal" or "shorten"',
    aiReviseRunButton: 'Generate revision',
    aiReviseSuggestionLabel: 'Suggested revision:',
    aiReviseChangesLabel: 'Changes:',
    aiReviseAccept: 'Accept',
    aiReviseReject: 'Reject',
    formatBold: 'Bold',
    formatItalic: 'Italic',
    formatHeading: 'Heading',
    formatBullet: 'Bullet list',
    formatNumbered: 'Numbered list',
    emptyListMessage: 'You have no drafts yet.',
    emptyListAction: 'New draft',
    exporting: 'Exporting…',
    exportFailed: 'Export failed',
    saveFailed: 'Save failed',
    newDraft: 'New draft',
    templatesTitle: 'Start a new draft',
    templatesSubtitle: 'Pick a template or start blank.',
    templateBlankTitle: 'Blank',
    templateBlankDescription: 'Start with an empty page.',
    templateLetterTitle: 'Letter',
    templateLetterDescription: 'Formal letter to a counterparty.',
    templateAppealTitle: 'Appeal',
    templateAppealDescription: 'Appeal or complaint to a court or authority.',
    templateMemoTitle: 'Memo',
    templateMemoDescription: 'Legal memo or analysis note.',
    templateContractReplyTitle: 'Contract review reply',
    templateContractReplyDescription:
        'Reply to a counterparty about contract review findings.',
    templateContractReplyLocked:
        'Available after your first contract review.',
    templateStarterTitleBlank: 'Untitled draft',
    templateStarterTitleLetter: 'Letter',
    templateStarterTitleAppeal: 'Appeal',
    templateStarterTitleMemo: 'Legal memo',
    templateStarterTitleContractReply: 'Contract review reply',
    templateStarterBodyBlank: '',
    templateStarterBodyLetter:
        '[Recipient name]\n[Recipient address]\n\n[Date]\n\n**Subject:** [topic]\n\nDear [Name],\n\n[Opening paragraph — context and purpose.]\n\n[Body — substantive points.]\n\n[Closing paragraph — requested action and timeline.]\n\nKind regards,\n[Your name]\n',
    templateStarterBodyAppeal:
        '# Appeal\n\n**To:** [Court / authority]\n**Case no.:** [number]\n**Appellant:** [name]\n**Date:** [date]\n\n## Decision being appealed\n[Identify decision date, body, file number.]\n\n## Grounds for appeal\n1. [First ground — fact / law.]\n2. [Second ground.]\n\n## Requested relief\n[State what the appellant asks the body to do.]\n\n## Signature\n[Name]\n',
    templateStarterBodyMemo:
        '# Legal memo\n\n**To:** [recipient]\n**From:** [author]\n**Date:** [date]\n**Re:** [matter]\n\n## Question presented\n[One-sentence framing of the issue.]\n\n## Short answer\n[Two-sentence conclusion.]\n\n## Facts\n[Material facts.]\n\n## Analysis\n[Apply law to facts.]\n\n## Conclusion\n[Final recommendation.]\n',
    templateStarterBodyContractReply:
        '# Reply on contract review\n\n**To:** [counterparty]\n**Re:** [contract title]\n**Date:** [date]\n\nDear [Name],\n\nWe have reviewed the draft contract you sent and would like to propose the following adjustments:\n\n1. **[Clause]** — [requested change and rationale].\n2. **[Clause]** — [requested change and rationale].\n3. **[Clause]** — [requested change and rationale].\n\nWe remain happy to discuss any of the above. We aim to finalise by [date].\n\nKind regards,\n[Your name]\n',
    versionsTitle: 'Version history',
    versionsEmpty: 'No previous versions yet.',
    versionsAiBadge: 'AI revision',
    versionsRestoreAction: 'Restore',
    versionsRestoreConfirmTitle: 'Restore this version?',
    versionsRestoreConfirmMessage:
        'Your current draft will be saved as a new snapshot first, so you can undo this.',
    versionsRestoreConfirmAction: 'Restore',
    versionsRestoreSuccess: 'Version restored',
    versionsRestoreFailed: 'Restore failed',
    versionHistory: 'Version history',
    saveToVault: 'Save to Vault',
    savedToVault: 'Saved to Vault',
    pdfWorkerUnavailable: 'PDF export is temporarily unavailable — try DOCX.',
    savingToVault: 'Saving to Vault…',
    saveToVaultFailed: 'Could not save to Vault',
    openInVault: 'Open in Vault',
    vaultNoteChip: 'Vault Note',
    vaultNoteTitlePrefix: 'Note: ',
    editInStudio: 'Edit in Studio',
  ),
  'et': const _Strings(
    title: 'Mustandite stuudio',
    empty: 'Tühi mustand',
    placeholder: 'Alusta mustandi kirjutamist…',
    draftsList: 'Minu mustandid',
    save: 'Salvesta',
    saved: 'Salvestatud',
    savedJustNow: 'Salvestatud just nüüd',
    aiRevise: 'AI ümbersõnastus',
    exportPdf: 'Ekspordi PDF',
    exportDocx: 'Ekspordi DOCX',
    exportMd: 'Ekspordi Markdown',
    deleteDraft: 'Kustuta mustand',
    confirmDelete: 'Kas kustutada see mustand?',
    confirmDeleteMessage: 'Seda toimingut ei saa tagasi võtta.',
    confirm: 'Kustuta',
    cancel: 'Tühista',
    draftReplyTo: 'Vastus: {name}',
    untitled: 'Pealkirjata',
    titleHint: 'Pealkiri (valikuline)',
    aiReviseTitle: 'AI ümbersõnastus',
    aiReviseSelectionLabel: 'Valitud tekst:',
    aiReviseInstructionLabel: 'Juhend (valikuline)',
    aiReviseInstructionHint:
        'nt "sõnasta ametlikumalt" või "tee lühemaks"',
    aiReviseRunButton: 'Genereeri ümbersõnastus',
    aiReviseSuggestionLabel: 'Soovitatud ümbersõnastus:',
    aiReviseChangesLabel: 'Muudatused:',
    aiReviseAccept: 'Kinnita',
    aiReviseReject: 'Lükka tagasi',
    formatBold: 'Rasvane',
    formatItalic: 'Kursiiv',
    formatHeading: 'Pealkiri',
    formatBullet: 'Loend',
    formatNumbered: 'Nummerdatud loend',
    emptyListMessage: 'Sul pole veel mustandeid.',
    emptyListAction: 'Uus mustand',
    exporting: 'Ekspordin…',
    exportFailed: 'Eksport ebaõnnestus',
    saveFailed: 'Salvestamine ebaõnnestus',
    newDraft: 'Uus mustand',
    templatesTitle: 'Alusta uut mustandit',
    templatesSubtitle: 'Vali mall või alusta tühjalt.',
    templateBlankTitle: 'Tühi',
    templateBlankDescription: 'Alusta tühja lehega.',
    templateLetterTitle: 'Kiri',
    templateLetterDescription: 'Ametlik kiri vastaspoolele.',
    templateAppealTitle: 'Kaebus',
    templateAppealDescription: 'Kaebus või vaie kohtule või ametiasutusele.',
    templateMemoTitle: 'Memo',
    templateMemoDescription: 'Õigusmemo või analüüs.',
    templateContractReplyTitle: 'Lepingu ülevaate vastus',
    templateContractReplyDescription:
        'Vasta vastaspoolele lepingu ülevaate märkuste kohta.',
    templateContractReplyLocked:
        'Saadaval pärast esimest lepingu ülevaadet.',
    templateStarterTitleBlank: 'Pealkirjata mustand',
    templateStarterTitleLetter: 'Kiri',
    templateStarterTitleAppeal: 'Kaebus',
    templateStarterTitleMemo: 'Õigusmemo',
    templateStarterTitleContractReply: 'Lepingu ülevaate vastus',
    templateStarterBodyBlank: '',
    templateStarterBodyLetter:
        '[Saaja nimi]\n[Saaja aadress]\n\n[Kuupäev]\n\n**Teema:** [teema]\n\nLugupeetud [nimi],\n\n[Sissejuhatus — kontekst ja eesmärk.]\n\n[Sisu — sisulised punktid.]\n\n[Lõpetus — palutav tegevus ja tähtaeg.]\n\nLugupidamisega,\n[Teie nimi]\n',
    templateStarterBodyAppeal:
        '# Kaebus\n\n**Saaja:** [kohus / ametiasutus]\n**Asja nr:** [number]\n**Kaebaja:** [nimi]\n**Kuupäev:** [kuupäev]\n\n## Vaidlustatav otsus\n[Otsuse kuupäev, asutus, viitenumber.]\n\n## Kaebuse alused\n1. [Esimene alus — fakt / õigus.]\n2. [Teine alus.]\n\n## Taotletav lahendus\n[Mida kaebaja palub.]\n\n## Allkiri\n[Nimi]\n',
    templateStarterBodyMemo:
        '# Õigusmemo\n\n**Saaja:** [adressaat]\n**Autor:** [autor]\n**Kuupäev:** [kuupäev]\n**Teema:** [küsimus]\n\n## Küsimus\n[Üks lause küsimuse kohta.]\n\n## Lühivastus\n[Kaks lauset järelduse kohta.]\n\n## Asjaolud\n[Olulised faktid.]\n\n## Analüüs\n[Õiguse kohaldamine.]\n\n## Järeldus\n[Lõplik soovitus.]\n',
    templateStarterBodyContractReply:
        '# Vastus lepingu ülevaatele\n\n**Saaja:** [vastaspool]\n**Teema:** [lepingu nimi]\n**Kuupäev:** [kuupäev]\n\nLugupeetud [nimi],\n\nOleme tutvunud teie saadetud lepingu projektiga ja soovime teha järgmised parandused:\n\n1. **[Punkt]** — [muudatus ja põhjendus].\n2. **[Punkt]** — [muudatus ja põhjendus].\n3. **[Punkt]** — [muudatus ja põhjendus].\n\nOleme valmis kõike eeltoodut arutama. Soovime jõuda kokkuleppele [kuupäevaks].\n\nLugupidamisega,\n[Teie nimi]\n',
    versionsTitle: 'Versioonide ajalugu',
    versionsEmpty: 'Eelmisi versioone veel pole.',
    versionsAiBadge: 'AI ümbersõnastus',
    versionsRestoreAction: 'Taasta',
    versionsRestoreConfirmTitle: 'Kas taastada see versioon?',
    versionsRestoreConfirmMessage:
        'Praegune mustand salvestatakse esmalt uue hetktõmmisena, nii saad selle taastada.',
    versionsRestoreConfirmAction: 'Taasta',
    versionsRestoreSuccess: 'Versioon taastatud',
    versionsRestoreFailed: 'Taastamine ebaõnnestus',
    versionHistory: 'Versioonide ajalugu',
    saveToVault: 'Salvesta hoidlasse',
    savedToVault: 'Salvestatud hoidlasse',
    pdfWorkerUnavailable:
        'PDF-eksport pole hetkel saadaval — proovi DOCX-i.',
    savingToVault: 'Salvestan hoidlasse…',
    saveToVaultFailed: 'Hoidlasse salvestamine ebaõnnestus',
    openInVault: 'Ava hoidlas',
    vaultNoteChip: 'Hoidla märkus',
    vaultNoteTitlePrefix: 'Märkus: ',
    editInStudio: 'Muuda stuudios',
  ),
  'fi': const _Strings(
    title: 'Luonnosstudio',
    empty: 'Tyhjä luonnos',
    placeholder: 'Aloita luonnoksen kirjoittaminen…',
    draftsList: 'Omat luonnokset',
    save: 'Tallenna',
    saved: 'Tallennettu',
    savedJustNow: 'Tallennettu juuri nyt',
    aiRevise: 'AI-uudelleenmuotoilu',
    exportPdf: 'Vie PDF',
    exportDocx: 'Vie DOCX',
    exportMd: 'Vie Markdown',
    deleteDraft: 'Poista luonnos',
    confirmDelete: 'Poistetaanko tämä luonnos?',
    confirmDeleteMessage: 'Tätä toimintoa ei voi peruuttaa.',
    confirm: 'Poista',
    cancel: 'Peruuta',
    draftReplyTo: 'Vastaus: {name}',
    untitled: 'Nimetön',
    titleHint: 'Otsikko (valinnainen)',
    aiReviseTitle: 'AI-uudelleenmuotoilu',
    aiReviseSelectionLabel: 'Valittu teksti:',
    aiReviseInstructionLabel: 'Ohje (valinnainen)',
    aiReviseInstructionHint:
        'esim. "muotoile virallisemmaksi" tai "lyhennä"',
    aiReviseRunButton: 'Tuota uudelleenmuotoilu',
    aiReviseSuggestionLabel: 'Ehdotettu uudelleenmuotoilu:',
    aiReviseChangesLabel: 'Muutokset:',
    aiReviseAccept: 'Hyväksy',
    aiReviseReject: 'Hylkää',
    formatBold: 'Lihavointi',
    formatItalic: 'Kursivointi',
    formatHeading: 'Otsikko',
    formatBullet: 'Luettelo',
    formatNumbered: 'Numeroitu luettelo',
    emptyListMessage: 'Sinulla ei ole vielä luonnoksia.',
    emptyListAction: 'Uusi luonnos',
    exporting: 'Viedään…',
    exportFailed: 'Vienti epäonnistui',
    saveFailed: 'Tallennus epäonnistui',
    newDraft: 'Uusi luonnos',
    templatesTitle: 'Aloita uusi luonnos',
    templatesSubtitle: 'Valitse malli tai aloita tyhjältä.',
    templateBlankTitle: 'Tyhjä',
    templateBlankDescription: 'Aloita tyhjältä sivulta.',
    templateLetterTitle: 'Kirje',
    templateLetterDescription: 'Virallinen kirje vastapuolelle.',
    templateAppealTitle: 'Valitus',
    templateAppealDescription:
        'Valitus tai oikaisuvaatimus tuomioistuimelle tai viranomaiselle.',
    templateMemoTitle: 'Muistio',
    templateMemoDescription: 'Oikeudellinen muistio tai analyysi.',
    templateContractReplyTitle: 'Vastaus sopimuksen tarkistukseen',
    templateContractReplyDescription:
        'Vastaa vastapuolelle sopimuksen tarkistuksen havainnoista.',
    templateContractReplyLocked:
        'Saatavilla ensimmäisen sopimustarkistuksen jälkeen.',
    templateStarterTitleBlank: 'Nimetön luonnos',
    templateStarterTitleLetter: 'Kirje',
    templateStarterTitleAppeal: 'Valitus',
    templateStarterTitleMemo: 'Oikeudellinen muistio',
    templateStarterTitleContractReply: 'Vastaus sopimustarkistukseen',
    templateStarterBodyBlank: '',
    templateStarterBodyLetter:
        '[Vastaanottajan nimi]\n[Vastaanottajan osoite]\n\n[Päivämäärä]\n\n**Aihe:** [aihe]\n\nHyvä [nimi],\n\n[Aloituskappale — tausta ja tarkoitus.]\n\n[Pääosa — keskeiset kohdat.]\n\n[Loppukappale — pyydetty toimenpide ja aikataulu.]\n\nYstävällisin terveisin,\n[Nimesi]\n',
    templateStarterBodyAppeal:
        '# Valitus\n\n**Vastaanottaja:** [tuomioistuin / viranomainen]\n**Asianumero:** [numero]\n**Valittaja:** [nimi]\n**Päiväys:** [päivämäärä]\n\n## Valituksen kohteena oleva päätös\n[Päätöksen päivämäärä, antaja, diaarinumero.]\n\n## Valitusperusteet\n1. [Ensimmäinen peruste — tosiseikka / oikeus.]\n2. [Toinen peruste.]\n\n## Vaadittu ratkaisu\n[Mitä valittaja vaatii.]\n\n## Allekirjoitus\n[Nimi]\n',
    templateStarterBodyMemo:
        '# Oikeudellinen muistio\n\n**Vastaanottaja:** [vastaanottaja]\n**Laatija:** [laatija]\n**Päiväys:** [päivämäärä]\n**Aihe:** [asia]\n\n## Kysymys\n[Yksi lause kysymyksestä.]\n\n## Lyhyt vastaus\n[Kaksi lausetta johtopäätöksestä.]\n\n## Tosiseikat\n[Olennaiset tosiseikat.]\n\n## Analyysi\n[Oikeuden soveltaminen.]\n\n## Johtopäätös\n[Lopullinen suositus.]\n',
    templateStarterBodyContractReply:
        '# Vastaus sopimustarkistukseen\n\n**Vastaanottaja:** [vastapuoli]\n**Aihe:** [sopimuksen nimi]\n**Päiväys:** [päivämäärä]\n\nHyvä [nimi],\n\nOlemme käyneet läpi lähettämänne sopimusluonnoksen ja ehdotamme seuraavia muutoksia:\n\n1. **[Kohta]** — [muutos ja perustelu].\n2. **[Kohta]** — [muutos ja perustelu].\n3. **[Kohta]** — [muutos ja perustelu].\n\nKeskustelemme mielellämme yllä olevista kohdista. Tavoitteenamme on saada sopimus valmiiksi [päivämäärään] mennessä.\n\nYstävällisin terveisin,\n[Nimesi]\n',
    versionsTitle: 'Versiohistoria',
    versionsEmpty: 'Aiempia versioita ei vielä ole.',
    versionsAiBadge: 'AI-muotoilu',
    versionsRestoreAction: 'Palauta',
    versionsRestoreConfirmTitle: 'Palautetaanko tämä versio?',
    versionsRestoreConfirmMessage:
        'Nykyinen luonnos tallennetaan ensin uudeksi tilannekuvaksi, jotta voit kumota toiminnon.',
    versionsRestoreConfirmAction: 'Palauta',
    versionsRestoreSuccess: 'Versio palautettu',
    versionsRestoreFailed: 'Palautus epäonnistui',
    versionHistory: 'Versiohistoria',
    saveToVault: 'Tallenna holviin',
    savedToVault: 'Tallennettu holviin',
    pdfWorkerUnavailable:
        'PDF-vienti ei ole tilapäisesti käytettävissä — kokeile DOCX:ää.',
    savingToVault: 'Tallennetaan holviin…',
    saveToVaultFailed: 'Holviin tallennus epäonnistui',
    openInVault: 'Avaa holvissa',
    vaultNoteChip: 'Holvimerkintä',
    vaultNoteTitlePrefix: 'Muistio: ',
    editInStudio: 'Muokkaa studiossa',
  ),
  'ru': const _Strings(
    title: 'Студия черновиков',
    empty: 'Пустой черновик',
    placeholder: 'Начните писать черновик…',
    draftsList: 'Мои черновики',
    save: 'Сохранить',
    saved: 'Сохранено',
    savedJustNow: 'Сохранено только что',
    aiRevise: 'Переработать с ИИ',
    exportPdf: 'Экспорт PDF',
    exportDocx: 'Экспорт DOCX',
    exportMd: 'Экспорт Markdown',
    deleteDraft: 'Удалить черновик',
    confirmDelete: 'Удалить этот черновик?',
    confirmDeleteMessage: 'Это действие необратимо.',
    confirm: 'Удалить',
    cancel: 'Отмена',
    draftReplyTo: 'Ответ: {name}',
    untitled: 'Без названия',
    titleHint: 'Заголовок (необязательно)',
    aiReviseTitle: 'Переработать с ИИ',
    aiReviseSelectionLabel: 'Выделенный текст:',
    aiReviseInstructionLabel: 'Инструкция (необязательно)',
    aiReviseInstructionHint:
        'например "сделать более формальным" или "сократить"',
    aiReviseRunButton: 'Создать переработку',
    aiReviseSuggestionLabel: 'Предлагаемая переработка:',
    aiReviseChangesLabel: 'Изменения:',
    aiReviseAccept: 'Принять',
    aiReviseReject: 'Отклонить',
    formatBold: 'Жирный',
    formatItalic: 'Курсив',
    formatHeading: 'Заголовок',
    formatBullet: 'Маркированный список',
    formatNumbered: 'Нумерованный список',
    emptyListMessage: 'Черновиков пока нет.',
    emptyListAction: 'Новый черновик',
    exporting: 'Экспортирую…',
    exportFailed: 'Экспорт не удался',
    saveFailed: 'Не удалось сохранить',
    newDraft: 'Новый черновик',
    templatesTitle: 'Создать новый черновик',
    templatesSubtitle: 'Выберите шаблон или начните с пустого.',
    templateBlankTitle: 'Пустой',
    templateBlankDescription: 'Начните с чистой страницы.',
    templateLetterTitle: 'Письмо',
    templateLetterDescription: 'Официальное письмо контрагенту.',
    templateAppealTitle: 'Жалоба',
    templateAppealDescription: 'Жалоба или апелляция в суд или орган власти.',
    templateMemoTitle: 'Меморандум',
    templateMemoDescription: 'Юридический меморандум или анализ.',
    templateContractReplyTitle: 'Ответ на проверку договора',
    templateContractReplyDescription:
        'Ответ контрагенту по результатам проверки договора.',
    templateContractReplyLocked:
        'Доступно после первой проверки договора.',
    templateStarterTitleBlank: 'Без названия',
    templateStarterTitleLetter: 'Письмо',
    templateStarterTitleAppeal: 'Жалоба',
    templateStarterTitleMemo: 'Юридический меморандум',
    templateStarterTitleContractReply: 'Ответ на проверку договора',
    templateStarterBodyBlank: '',
    templateStarterBodyLetter:
        '[Имя получателя]\n[Адрес получателя]\n\n[Дата]\n\n**Тема:** [тема]\n\nУважаемый/ая [имя],\n\n[Вступление — контекст и цель.]\n\n[Основная часть — содержательные пункты.]\n\n[Заключение — запрашиваемое действие и сроки.]\n\nС уважением,\n[Ваше имя]\n',
    templateStarterBodyAppeal:
        '# Жалоба\n\n**Кому:** [суд / орган]\n**Дело №:** [номер]\n**Заявитель:** [имя]\n**Дата:** [дата]\n\n## Обжалуемое решение\n[Дата, орган, регистрационный номер.]\n\n## Основания жалобы\n1. [Первое основание — факт / норма.]\n2. [Второе основание.]\n\n## Запрашиваемое решение\n[Что просит заявитель.]\n\n## Подпись\n[Имя]\n',
    templateStarterBodyMemo:
        '# Юридический меморандум\n\n**Кому:** [адресат]\n**От:** [автор]\n**Дата:** [дата]\n**Тема:** [вопрос]\n\n## Вопрос\n[Одно предложение по сути вопроса.]\n\n## Краткий ответ\n[Два предложения вывода.]\n\n## Факты\n[Существенные факты.]\n\n## Анализ\n[Применение права к фактам.]\n\n## Заключение\n[Итоговая рекомендация.]\n',
    templateStarterBodyContractReply:
        '# Ответ по проверке договора\n\n**Кому:** [контрагент]\n**Тема:** [название договора]\n**Дата:** [дата]\n\nУважаемый/ая [имя],\n\nМы рассмотрели присланный вами проект договора и предлагаем внести следующие изменения:\n\n1. **[Пункт]** — [изменение и обоснование].\n2. **[Пункт]** — [изменение и обоснование].\n3. **[Пункт]** — [изменение и обоснование].\n\nГотовы обсудить любой из вышеуказанных пунктов. Стремимся согласовать договор до [дата].\n\nС уважением,\n[Ваше имя]\n',
    versionsTitle: 'История версий',
    versionsEmpty: 'Предыдущих версий пока нет.',
    versionsAiBadge: 'ИИ-правка',
    versionsRestoreAction: 'Восстановить',
    versionsRestoreConfirmTitle: 'Восстановить эту версию?',
    versionsRestoreConfirmMessage:
        'Текущий черновик сначала будет сохранён как новая копия, чтобы вы могли отменить действие.',
    versionsRestoreConfirmAction: 'Восстановить',
    versionsRestoreSuccess: 'Версия восстановлена',
    versionsRestoreFailed: 'Не удалось восстановить',
    versionHistory: 'История версий',
    saveToVault: 'Сохранить в Сейф',
    savedToVault: 'Сохранено в Сейф',
    pdfWorkerUnavailable:
        'Экспорт PDF временно недоступен — попробуйте DOCX.',
    savingToVault: 'Сохраняю в Сейф…',
    saveToVaultFailed: 'Не удалось сохранить в Сейф',
    openInVault: 'Открыть в Сейфе',
    vaultNoteChip: 'Заметка Сейфа',
    vaultNoteTitlePrefix: 'Заметка: ',
    editInStudio: 'Открыть в студии',
  ),
};
