// Advocat icon vocabulary — single source of truth for app glyphs.
//
// Why this file exists:
//   The app previously sprayed `Icons.*` (Material 3 generic) across screens,
//   making Advocat look like every other Flutter app. Competitive products
//   (Harvey / DoNotPay / Spellbook) ship a custom icon vocabulary that signals
//   "legal-tech tool", not "default Material demo".
//
// Choice: Phosphor Icons regular variant.
//   - 1.5px stroke pairs visually with Inter typography weight used in
//     `lib/config/theme.dart`.
//   - MIT licensed.
//   - Thin variant used for large empty-state illustrations.
//
// Usage:
//   import 'package:advocat/core/icons/app_icons.dart';
//   Icon(AppIcons.chat)
//   Icon(AppIcons.emptyDocuments, size: 64, color: AppColors.textTertiary)
//
// Migration policy:
//   - New screens / refactored screens MUST use AppIcons.*
//   - Existing Icons.* call sites are migrated screen-by-screen, not big-bang.
//   - When you need a glyph that isn't here, add it to AppIcons rather than
//     reaching for Icons.* directly.
//
// Adding a new icon:
//   1. Pick from https://phosphoricons.com/ (Regular variant).
//   2. Add as `static const IconData yourName = PhosphorIconsRegular.foo;`
//   3. Update `test/core/icons/app_icons_test.dart` so CI catches accidental
//      removal.

import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Advocat brand icon vocabulary.
///
/// Use ONLY these constants in feature code instead of `Icons.*` (Material).
/// Phosphor `Regular` variant matches Inter typography weight; `Thin` is
/// reserved for oversized empty-state glyphs.
abstract final class AppIcons {
  // ----- Chat & AI -----
  /// Chat thread / conversation entry point.
  static const IconData chat = PhosphorIconsRegular.chatCircleText;

  /// AI / LLM reasoning indicator.
  static const IconData ai = PhosphorIconsRegular.brain;

  /// Multi-lawyer consilium / panel of experts.
  static const IconData consilium = PhosphorIconsRegular.users;

  // ----- Documents & Legal -----
  /// Generic document (letters, evidence, PDFs).
  static const IconData document = PhosphorIconsRegular.fileText;

  /// Document-type tag: PDF file (vault, attachments).
  static const IconData documentPdf = PhosphorIconsRegular.filePdf;

  /// Document-type tag: image file (vault, attachments).
  static const IconData documentImage = PhosphorIconsRegular.fileImage;

  /// Contract / signed agreement. Phosphor's `certificate` glyph reads as
  /// "executed legal document" — distinct from `draft` (notePencil), which
  /// signals work-in-progress composition.
  static const IconData contract = PhosphorIconsRegular.certificate;

  /// OCR / camera-document scan action.
  static const IconData scan = PhosphorIconsRegular.scan;

  /// Encrypted document vault.
  static const IconData vault = PhosphorIconsRegular.vault;

  /// Drafting studio / compose draft.
  static const IconData draft = PhosphorIconsRegular.notePencil;

  // ----- Cases -----
  /// Case folder.
  static const IconData caseFolder = PhosphorIconsRegular.folder;

  /// Deadline countdown / radar.
  static const IconData deadline = PhosphorIconsRegular.clockCountdown;

  /// Urgent / severity-high indicator.
  static const IconData urgent = PhosphorIconsRegular.warning;

  // ----- Actions -----
  /// Send message / email.
  static const IconData send = PhosphorIconsRegular.paperPlaneTilt;

  /// Attach file in chat composer.
  static const IconData attach = PhosphorIconsRegular.paperclip;

  /// Voice / dictation input.
  static const IconData mic = PhosphorIconsRegular.microphone;

  /// Camera capture (intake photos, ID scans).
  static const IconData camera = PhosphorIconsRegular.camera;

  // ----- Navigation -----
  /// Home tab.
  static const IconData home = PhosphorIconsRegular.house;

  /// Email Agent inbox.
  static const IconData inbox = PhosphorIconsRegular.envelope;

  /// Settings tab.
  static const IconData settings = PhosphorIconsRegular.gear;

  // ----- Empty states (thin variant, larger glyph for hero illustrations) -----
  /// Empty-state hero for documents/vault list.
  static const IconData emptyDocuments = PhosphorIconsThin.folderOpen;

  /// Empty-state hero for inbox.
  static const IconData emptyInbox = PhosphorIconsThin.envelopeOpen;

  /// Empty-state hero for deadlines list.
  static const IconData emptyDeadlines = PhosphorIconsThin.clock;

  /// All non-empty-state glyphs (for tests / migration linting).
  static const List<IconData> all = <IconData>[
    chat,
    ai,
    consilium,
    document,
    documentPdf,
    documentImage,
    contract,
    scan,
    vault,
    draft,
    caseFolder,
    deadline,
    urgent,
    send,
    attach,
    mic,
    camera,
    home,
    inbox,
    settings,
  ];

  /// Empty-state glyph subset.
  static const List<IconData> emptyStates = <IconData>[
    emptyDocuments,
    emptyInbox,
    emptyDeadlines,
  ];
}
