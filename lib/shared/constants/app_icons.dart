import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Central registry of all icon definitions used throughout the app.
///
/// Using a single source of truth avoids scattered magic icon references
/// and makes it trivial to swap icon sets later.
abstract final class AppIcons {
  // ── Navigation ──────────────────────────────────────────────────────────
  static const IconData home = Icons.home_rounded;
  static const IconData homeOutlined = Icons.home_outlined;
  static const IconData cases = Icons.folder_rounded;
  static const IconData casesOutlined = Icons.folder_outlined;
  static const IconData scan = Icons.camera_alt_rounded;
  static const IconData scanOutlined = Icons.camera_alt_outlined;
  static const IconData deadlines = Icons.schedule_rounded;
  static const IconData deadlinesOutlined = Icons.schedule_outlined;
  static const IconData settings = Icons.settings_rounded;
  static const IconData settingsOutlined = Icons.settings_outlined;

  // ── Settings ────────────────────────────────────────────────────────────
  static const IconData profile = Icons.person_rounded;
  static const IconData profileOutlined = Icons.person_outline_rounded;
  static const IconData language = Icons.language_rounded;
  static const IconData subscription = Icons.workspace_premium_rounded;
  static const IconData subscriptionOutlined = Icons.workspace_premium_outlined;
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData notificationsOutlined = Icons.notifications_outlined;
  static const IconData email = Icons.email_rounded;
  static const IconData emailOutlined = Icons.email_outlined;
  static const IconData privacy = Icons.shield_rounded;
  static const IconData privacyOutlined = Icons.shield_outlined;
  static const IconData terms = Icons.description_rounded;
  static const IconData termsOutlined = Icons.description_outlined;
  static const IconData info = Icons.info_rounded;
  static const IconData infoOutlined = Icons.info_outline_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData editOutlined = Icons.edit_outlined;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutlined = Icons.star_outline_rounded;
  static const IconData support = Icons.headset_mic_rounded;
  static const IconData supportOutlined = Icons.headset_mic_outlined;
  static const IconData dataExport = Icons.download_rounded;
  static const IconData deleteAccount = Icons.delete_forever_rounded;

  // ── Documents & Cases ──────────────────────────────────────────────────
  static const IconData document = Icons.insert_drive_file_rounded;
  static const IconData documentOutlined = Icons.insert_drive_file_outlined;
  static const IconData upload = Icons.upload_file_rounded;
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData gallery = Icons.photo_library_rounded;
  static const IconData pdf = Icons.picture_as_pdf_rounded;
  static const IconData attach = Icons.attach_file_rounded;

  // ── Actions ─────────────────────────────────────────────────────────────
  static const IconData add = Icons.add_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData link = Icons.link_rounded;

  // ── Status ──────────────────────────────────────────────────────────────
  static const IconData statusActive = Icons.circle;
  static const IconData statusPending = Icons.pending_rounded;
  static const IconData statusDone = Icons.task_alt_rounded;
  static const IconData timer = Icons.timer_rounded;
  static const IconData urgent = Icons.priority_high_rounded;

  // ── Chat / AI ──────────────────────────────────────────────────────────
  static const IconData chat = Icons.chat_rounded;
  static const IconData chatOutlined = Icons.chat_outlined;
  static const IconData send = Icons.send_rounded;
  static const IconData ai = Icons.auto_awesome_rounded;

  // ── Cupertino alternatives (iOS-native feel) ──────────────────────────
  static const IconData cupertinoHome = CupertinoIcons.house_fill;
  static const IconData cupertinoSettings = CupertinoIcons.gear;
  static const IconData cupertinoProfile = CupertinoIcons.person_fill;
  static const IconData cupertinoChevronRight = CupertinoIcons.chevron_right;
  static const IconData cupertinoSearch = CupertinoIcons.search;
}
