// access_log_screen.dart — Data Fortress Pillar 3: "Access log for my data".
// Shows the user a transparent, tamper-evident record of who/what/when
// touched their data, with a local chain-integrity check.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../services/access_log_service.dart';

class AccessLogScreen extends ConsumerStatefulWidget {
  const AccessLogScreen({super.key});

  @override
  ConsumerState<AccessLogScreen> createState() => _AccessLogScreenState();
}

class _AccessLogScreenState extends ConsumerState<AccessLogScreen> {
  late final AccessLogService _service =
      AccessLogService(Supabase.instance.client);

  List<AccessLogEntry>? _entries;
  ChainVerification? _chain;
  List<BreachAlertEntry> _breaches = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _service.fetch(limit: 100);
      final chain = _service.verifyChain(entries);
      // Breach alerts are GDPR Art. 34 — surface them prominently. Best-effort:
      // a failure here must not hide the access log itself.
      List<BreachAlertEntry> breaches = const [];
      try {
        breaches = await _service.fetchBreachAlerts();
      } catch (_) {/* ignore — log still shows */}
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _chain = chain;
        _breaches = breaches;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.accessLogTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context, l),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.accessLogError, textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    }
    final entries = _entries ?? const [];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Intro — explain what this is.
        Text(l.accessLogIntro, style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        )),
        const SizedBox(height: AppSpacing.md),
        if (_breaches.isNotEmpty) ...[
          _BreachBanner(breaches: _breaches, l: l),
          const SizedBox(height: AppSpacing.md),
        ],
        _IntegrityBanner(chain: _chain, l: l),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: Text(l.accessLogEmpty)),
          )
        else
          ...entries.map((e) => _AccessRow(entry: e, l: l)),
      ],
    );
  }
}

class _IntegrityBanner extends StatelessWidget {
  const _IntegrityBanner({required this.chain, required this.l});
  final ChainVerification? chain;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final intact = chain?.intact ?? true;
    final color = intact ? AppColors.success : AppColors.error;
    final icon = intact ? Icons.verified_user_outlined : Icons.warning_amber;
    final text = intact ? l.accessLogIntegrityOk : l.accessLogIntegrityBroken;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _BreachBanner extends StatelessWidget {
  const _BreachBanner({required this.breaches, required this.l});
  final List<BreachAlertEntry> breaches;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe_outlined, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.breachAlertTitle,
                  style: const TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.breachAlertBody, style: const TextStyle(
            color: color,
            fontSize: 12,
            height: 1.4,
          )),
          for (final b in breaches)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '• ${_fmt(b.detectedAt)} — ${b.kind} (${b.severity})',
                style: const TextStyle(color: color, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime ts) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${ts.year}-${two(ts.month)}-${two(ts.day)} '
        '${two(ts.hour)}:${two(ts.minute)}';
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.entry, required this.l});
  final AccessLogEntry entry;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(entry.action), size: 18, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelFor(entry.action, l),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(_fmtTs(entry.ts),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String action) {
    switch (action) {
      case 'llm_egress':
      case 'ai_analysis':
        return Icons.smart_toy_outlined;
      case 'document_parse':
      case 'pdf_upload':
        return Icons.description_outlined;
      case 'staff_read':
      case 'admin_access':
        return Icons.person_outline;
      case 'export_data':
        return Icons.download_outlined;
      case 'email_triage':
        return Icons.mail_outline;
      case 'deadline_scan':
        return Icons.event_outlined;
      default:
        return Icons.history;
    }
  }

  static String _labelFor(String action, AppLocalizations l) {
    switch (action) {
      case 'llm_egress':
        return l.accessActionLlmEgress;
      case 'ai_analysis':
        return l.accessActionAiAnalysis;
      case 'document_parse':
        return l.accessActionDocumentParse;
      case 'staff_read':
        return l.accessActionStaffRead;
      case 'export_data':
        return l.accessActionExport;
      case 'email_triage':
        return l.accessActionEmailTriage;
      case 'deadline_scan':
        return l.accessActionDeadlineScan;
      default:
        return action;
    }
  }

  static String _fmtTs(DateTime ts) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${ts.year}-${two(ts.month)}-${two(ts.day)} '
        '${two(ts.hour)}:${two(ts.minute)}';
  }
}
