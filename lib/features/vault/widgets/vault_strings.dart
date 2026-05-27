// features/vault/widgets/vault_strings.dart — Vault UI strings (locale-aware).
// -----------------------------------------------------------------------------
// Lightweight locale-aware string table for the new Vault UI affordances
// (chip row, search, delete sheet, encryption verbiage). Mirrors the
// `drafting_strings.dart` pattern in lib/features/drafting/ so we don't have
// to round-trip `flutter gen-l10n` for every iteration during the encryption
// + tagging rollout.
//
// Covers the four product-priority languages (et, fi, en, ru). Every other
// locale falls through to English. When the feature ships to all 17 locales
// these keys can be hoisted into the global ARB system in a single sweep.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class VaultStrings {
  const VaultStrings({
    required this.searchHint,
    required this.tagAll,
    required this.tagContract,
    required this.tagReceipt,
    required this.tagEmail,
    required this.tagEvidence,
    required this.tagIdPassport,
    required this.tagOther,
    required this.deleteFromVaultTitle,
    required this.deleteFromVaultMessage,
    required this.delete,
    required this.cancel,
    required this.documentDeleted,
    required this.deleteFailed,
    required this.encryptedWithYourKey,
    required this.tagPickerTitle,
  });

  final String searchHint;
  final String tagAll;
  final String tagContract;
  final String tagReceipt;
  final String tagEmail;
  final String tagEvidence;
  final String tagIdPassport;
  final String tagOther;
  final String deleteFromVaultTitle;
  final String deleteFromVaultMessage;
  final String delete;
  final String cancel;
  final String documentDeleted;
  final String deleteFailed;
  final String encryptedWithYourKey;
  final String tagPickerTitle;

  static VaultStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'et':
        return _et;
      case 'fi':
        return _fi;
      case 'ru':
        return _ru;
      default:
        return _en;
    }
  }

  /// Maps a tag slug to its localized label. Falls back to the tag's own
  /// label (which already came localized from the backend) when unknown.
  String labelForSlug(String slug, {String? fallback}) {
    switch (slug) {
      case 'contract':
        return tagContract;
      case 'receipt':
        return tagReceipt;
      case 'email':
        return tagEmail;
      case 'evidence':
        return tagEvidence;
      case 'id_passport':
        return tagIdPassport;
      case 'other':
        return tagOther;
      default:
        return fallback ?? slug;
    }
  }
}

// ── English (default) ────────────────────────────────────────────────────────
const _en = VaultStrings(
  searchHint: 'Search documents',
  tagAll: 'All',
  tagContract: 'Contract',
  tagReceipt: 'Receipt',
  tagEmail: 'Email',
  tagEvidence: 'Evidence',
  tagIdPassport: 'ID/Passport',
  tagOther: 'Other',
  deleteFromVaultTitle: 'Delete from Vault?',
  deleteFromVaultMessage:
      'This file will be permanently removed. This cannot be undone.',
  delete: 'Delete',
  cancel: 'Cancel',
  documentDeleted: 'Document deleted',
  deleteFailed: 'Could not delete document',
  encryptedWithYourKey:
      'Files encrypted with your personal key. Only you can read them.',
  tagPickerTitle: 'Tag this document',
);

// ── Estonian ─────────────────────────────────────────────────────────────────
const _et = VaultStrings(
  searchHint: 'Otsi dokumente',
  tagAll: 'Kõik',
  tagContract: 'Leping',
  tagReceipt: 'Kviitung',
  tagEmail: 'E-kiri',
  tagEvidence: 'Tõend',
  tagIdPassport: 'ID/Pass',
  tagOther: 'Muu',
  deleteFromVaultTitle: 'Kas kustutada hoidlast?',
  deleteFromVaultMessage:
      'Fail kustutatakse jäädavalt. Toimingut ei saa tagasi võtta.',
  delete: 'Kustuta',
  cancel: 'Tühista',
  documentDeleted: 'Dokument kustutatud',
  deleteFailed: 'Dokumendi kustutamine ebaõnnestus',
  encryptedWithYourKey:
      'Failid on krüpteeritud sinu isikliku võtmega. Ainult sina saad neid lugeda.',
  tagPickerTitle: 'Märgista dokument',
);

// ── Finnish ──────────────────────────────────────────────────────────────────
const _fi = VaultStrings(
  searchHint: 'Etsi asiakirjoja',
  tagAll: 'Kaikki',
  tagContract: 'Sopimus',
  tagReceipt: 'Kuitti',
  tagEmail: 'Sähköposti',
  tagEvidence: 'Todiste',
  tagIdPassport: 'ID/Passi',
  tagOther: 'Muu',
  deleteFromVaultTitle: 'Poistetaanko holvista?',
  deleteFromVaultMessage:
      'Tiedosto poistetaan pysyvästi. Tätä ei voi peruuttaa.',
  delete: 'Poista',
  cancel: 'Peruuta',
  documentDeleted: 'Asiakirja poistettu',
  deleteFailed: 'Asiakirjan poistaminen epäonnistui',
  encryptedWithYourKey:
      'Tiedostot on salattu omalla avaimellasi. Vain sinä voit lukea niitä.',
  tagPickerTitle: 'Merkitse asiakirja',
);

// ── Russian ──────────────────────────────────────────────────────────────────
const _ru = VaultStrings(
  searchHint: 'Поиск документов',
  tagAll: 'Все',
  tagContract: 'Договор',
  tagReceipt: 'Чек',
  tagEmail: 'Письмо',
  tagEvidence: 'Доказательство',
  tagIdPassport: 'ID/Паспорт',
  tagOther: 'Другое',
  deleteFromVaultTitle: 'Удалить из хранилища?',
  deleteFromVaultMessage:
      'Файл будет удалён без возможности восстановления.',
  delete: 'Удалить',
  cancel: 'Отмена',
  documentDeleted: 'Документ удалён',
  deleteFailed: 'Не удалось удалить документ',
  encryptedWithYourKey:
      'Файлы зашифрованы вашим личным ключом. Только вы можете их читать.',
  tagPickerTitle: 'Тег документа',
);
