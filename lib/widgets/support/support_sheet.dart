// widgets/support/support_sheet.dart
//
// Stripe-style help drawer. Opens from the SupportFab. Replaces the v3
// "ask a question" form that owner rejected as "sheet на клике белый
// пустой" — the new sheet shows real content the moment it opens:
//
//   * Header with title + green status dot + close button
//   * Search field (no-op for now; visual anchor so the sheet is never
//     blank, and a hook for FAQ search later)
//   * Top 5 FAQ rows, localised, each linking to the right destination
//   * Three contact channels (Email / Telegram / WhatsApp) shown only when
//     configured in `SupportConfig`
//   * Sticky footer with SLA copy + app version
//
// Layout:
//   * Desktop (>=600px): 380px right-anchored drawer, full viewport height,
//     mounted by SupportFab via `showGeneralDialog`. The transitions and
//     scrim live in SupportFab; this widget owns the column-layout only.
//   * Mobile: 85vh bottom sheet, dragged from `showModalBottomSheet`.
//     Drag-handle is drawn here at the top.
//
// Wire format:
//   * The widget is layout-only — it does NOT post tickets. The previous
//     in-app form / honeypot / SupportService submission have been removed
//     because owner's research showed users never filled them in; the
//     mailto: contact channel handles "talk to a human" with a real reply
//     address. SupportService and the support-ticket edge fn remain
//     available for future flows.
//
// l10n keys consumed (added in this commit; all also fall back to English
// when missing in a locale):
//   supportTitle, supportSearchPlaceholder, supportStatusAllOk,
//   supportFaqWhatIs, supportFaqHowSubscribe, supportFaqExportData,
//   supportFaqCancelAccount, supportFaqTalkHuman, supportContactEmail,
//   supportContactTelegram, supportContactWhatsapp, supportFooterSla.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import 'support_fab.dart' show kSupportTeal;

/// Drawer / bottom-sheet content. `asDrawer=true` renders the full-height
/// right-side panel used on desktop; `asDrawer=false` renders the mobile
/// bottom-sheet variant with a drag handle and rounded top corners.
class SupportSheet extends ConsumerWidget {
  const SupportSheet({super.key, this.asDrawer = false});

  final bool asDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!asDrawer) const _DragHandle(),
        _Header(loc: loc, asDrawer: asDrawer),
        const _Divider(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _SearchField(loc: loc),
                const SizedBox(height: 16),
                _FaqList(loc: loc),
                const SizedBox(height: 16),
                _ContactChannelsRow(loc: loc),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const _Divider(),
        _Footer(loc: loc),
      ],
    );

    final shape = asDrawer
        ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          )
        : const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          );

    return Material(
      color: colorScheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: asDrawer,
        bottom: false,
        child: body,
      ),
    );
  }
}

/// Top 64dp header with title, status pill, and close button.
class _Header extends StatelessWidget {
  const _Header({required this.loc, required this.asDrawer});
  final AppLocalizations? loc;
  final bool asDrawer;

  @override
  Widget build(BuildContext context) {
    final title = loc?.supportTitle ?? 'Help';
    final statusLabel = loc?.supportStatusAllOk ?? 'All systems normal';
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusPill(label: statusLabel),
                ],
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close, size: 20),
              color: const Color(0xFF475569),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981), // emerald-500
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE2E8F0),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Single-line search field. The query is currently a no-op visual anchor —
/// the sheet must NEVER look blank, so even an empty search row gives the
/// user something to look at while we wire up the FAQ index.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.loc});
  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    final hint = loc?.supportSearchPlaceholder ?? 'Search help…';
    return TextField(
      key: const ValueKey('support-search'),
      enabled: true,
      onSubmitted: (_) {}, // no-op until FAQ search ships
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kSupportTeal, width: 1.5),
        ),
      ),
    );
  }
}

/// Top 5 FAQ rows. Static for MVP — each row dispatches to the right
/// destination. Wired now so the sheet is never blank.
class _FaqList extends StatefulWidget {
  const _FaqList({required this.loc});
  final AppLocalizations? loc;

  @override
  State<_FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<_FaqList> {
  /// Toggled when the user taps "Talk to a human" — reveals the contact
  /// row below (a no-op on this widget; ContactChannelsRow is always
  /// rendered, this flag just scrolls focus to it visually).
  bool _talkToHumanExpanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final items = <_FaqItem>[
      _FaqItem(
        icon: Icons.info_outline,
        label: loc?.supportFaqWhatIs ?? 'What is Advocat?',
        onTap: () {
          Navigator.of(context).maybePop();
          context.go('/chat/general?prompt=What%20is%20Advocat%3F');
        },
      ),
      _FaqItem(
        icon: Icons.workspace_premium_outlined,
        label: loc?.supportFaqHowSubscribe ?? 'How do I subscribe to Pro?',
        onTap: () {
          Navigator.of(context).maybePop();
          context.go('/subscription');
        },
      ),
      _FaqItem(
        icon: Icons.download_outlined,
        label: loc?.supportFaqExportData ?? 'Can I export my data?',
        onTap: () {
          Navigator.of(context).maybePop();
          context.go('/settings');
        },
      ),
      _FaqItem(
        icon: Icons.no_accounts_outlined,
        label: loc?.supportFaqCancelAccount ?? 'Cancel / delete account',
        onTap: () {
          Navigator.of(context).maybePop();
          context.go('/settings');
        },
      ),
      _FaqItem(
        icon: Icons.support_agent_outlined,
        label: loc?.supportFaqTalkHuman ?? 'Talk to a human',
        onTap: () {
          // Reveal contact row hint — actual channels are below the FAQ
          // list, this just keeps the sheet open so the user can tap them.
          setState(() => _talkToHumanExpanded = true);
        },
        emphasised: _talkToHumanExpanded,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items.map((it) => _FaqRow(item: it)).toList(),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasised = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasised;
}

class _FaqRow extends StatefulWidget {
  const _FaqRow({required this.item});
  final _FaqItem item;

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovering
        ? const Color(0xFFF8FAFC)
        : (widget.item.emphasised
            ? const Color(0xFFECFDF5)
            : Colors.transparent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.item.onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: kSupportTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.item.icon,
                  size: 18,
                  color: const Color(0xFF475569),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three contact channels in a row. Email is always shown; Telegram and
/// WhatsApp are pulled from `SupportConfig` and hidden when unconfigured.
class _ContactChannelsRow extends StatelessWidget {
  const _ContactChannelsRow({required this.loc});
  final AppLocalizations? loc;

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: SupportConfig.supportEmail,
      query: 'subject=Advocat%20support&body=Hi%2C%20',
    );
    await launchUrl(uri);
  }

  Future<void> _openTelegram() async {
    const handle = SupportConfig.telegramHandle;
    if (handle.isEmpty) return;
    final uri = Uri.parse('https://t.me/$handle');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp() async {
    const number = SupportConfig.whatsappNumber;
    if (number.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$number');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _ContactTile(
        key: const ValueKey('support-contact-email'),
        icon: Icons.mail_outline,
        label: loc?.supportContactEmail ?? 'Email',
        onTap: _openEmail,
      ),
      if (SupportConfig.telegramAvailable)
        _ContactTile(
          key: const ValueKey('support-contact-telegram'),
          icon: Icons.send_outlined,
          label: loc?.supportContactTelegram ?? 'Telegram',
          onTap: _openTelegram,
        ),
      if (SupportConfig.whatsappAvailable)
        _ContactTile(
          key: const ValueKey('support-contact-whatsapp'),
          icon: Icons.chat_bubble_outline,
          label: loc?.supportContactWhatsapp ?? 'WhatsApp',
          onTap: _openWhatsApp,
        ),
    ];

    // Distribute evenly. With <3 tiles the row stays naturally centred via
    // mainAxisAlignment.spaceBetween + an outer SizedBox per item.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i < tiles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ContactTile extends StatefulWidget {
  const _ContactTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovering ? const Color(0xFFF8FAFC) : Colors.white;
    final borderColor =
        _hovering ? kSupportTeal.withValues(alpha: 0.5) : const Color(0xFFE2E8F0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: kSupportTeal.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 20, color: const Color(0xFF475569)),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky footer pinned at the bottom of the drawer: SLA copy + version.
class _Footer extends StatelessWidget {
  const _Footer({required this.loc});
  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    final sla = loc?.supportFooterSla ?? 'We respond within 24h';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              sla,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          const _AppVersionLabel(),
        ],
      ),
    );
  }
}

class _AppVersionLabel extends StatelessWidget {
  const _AppVersionLabel();
  @override
  Widget build(BuildContext context) {
    return const Text(
      'v${AppConfig.appVersion}',
      style: TextStyle(
        fontSize: 11,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
