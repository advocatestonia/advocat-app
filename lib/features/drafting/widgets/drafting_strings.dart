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
  ),
};
