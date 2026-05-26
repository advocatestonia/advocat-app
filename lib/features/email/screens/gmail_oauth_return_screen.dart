// Phase 2a (2026-05-27) — Gmail OAuth return route.
// ----------------------------------------------------------------------------
// Google's authorize redirect lands here at /oauth/gmail/return?code=&state=.
// This screen reads the query params, calls the gmail-oauth-exchange edge fn
// via OAuthStorageService.exchangeGmailCode, and pushes the user back to the
// /email screen with a status banner.
//
// Why a dedicated route (not a deep-link handler on /email): the redirect URI
// must be stable and match what's configured in Google Cloud Console for the
// OAuth client. Mounting it as its own route also lets us show a clear
// "Connecting Gmail…" state during the exchange call (which can take 1-3 s).
// ----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../services/oauth_storage_service.dart';

class GmailOAuthReturnScreen extends ConsumerStatefulWidget {
  const GmailOAuthReturnScreen({
    super.key,
    required this.code,
    required this.state,
    this.error,
  });

  /// `?code=` from Google's redirect. Single-use, server-side at Google.
  final String? code;

  /// `?state=` — signed JWT that the edge fn re-verifies.
  final String? state;

  /// `?error=` — set when Google rejected the consent (user denied, etc).
  final String? error;

  @override
  ConsumerState<GmailOAuthReturnScreen> createState() =>
      _GmailOAuthReturnScreenState();
}

class _GmailOAuthReturnScreenState
    extends ConsumerState<GmailOAuthReturnScreen> {
  _ExchangeStatus _status = _ExchangeStatus.exchanging;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    // Defer to next frame so Riverpod ProviderScope is fully bound before we
    // read it. Otherwise the test harness flakes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runExchange());
  }

  Future<void> _runExchange() async {
    // Early-exit: Google rejected the consent (e.g. user clicked "Cancel").
    if (widget.error != null && widget.error!.isNotEmpty) {
      setState(() {
        _status = _ExchangeStatus.failed;
        _errorDetail = widget.error;
      });
      _bounceBackAfterDelay();
      return;
    }
    final code = widget.code;
    final state = widget.state;
    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      setState(() {
        _status = _ExchangeStatus.failed;
        _errorDetail = 'Missing code or state in redirect URL';
      });
      _bounceBackAfterDelay();
      return;
    }
    try {
      final svc = ref.read(oauthStorageServiceProvider);
      final result = await svc.exchangeGmailCode(code: code, state: state);
      if (!mounted) return;
      if (!result.ok || result.hasRefreshToken != true) {
        setState(() {
          _status = _ExchangeStatus.failed;
          _errorDetail = result.hasRefreshToken == false
              ? 'Google did not return a refresh_token. Please revoke access at '
                  'https://myaccount.google.com/permissions and try again.'
              : 'Exchange completed but server reported failure.';
        });
        _bounceBackAfterDelay();
        return;
      }
      setState(() {
        _status = _ExchangeStatus.success;
      });
      // Brief success state, then return to /email so the user sees the
      // green "Gmail connected" banner there.
      _bounceBackAfterDelay(
        success: true,
        delay: const Duration(milliseconds: 800),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ExchangeStatus.failed;
        _errorDetail = e.toString();
      });
      _bounceBackAfterDelay();
    }
  }

  void _bounceBackAfterDelay({
    bool success = false,
    Duration delay = const Duration(seconds: 3),
  }) {
    Future<void>.delayed(delay, () {
      if (!mounted) return;
      // Use go (not push) so the back stack doesn't grow.
      context.go(
        '${AppRoutes.email}?gmail_connected=${success ? 1 : 0}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              switch (_status) {
                _ExchangeStatus.exchanging => const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(),
                  ),
                _ExchangeStatus.success => Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                _ExchangeStatus.failed => Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
              },
              const SizedBox(height: 16),
              Text(
                switch (_status) {
                  _ExchangeStatus.exchanging => 'Connecting Gmail…',
                  _ExchangeStatus.success => 'Gmail connected',
                  _ExchangeStatus.failed => 'Could not connect Gmail',
                },
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (_errorDetail != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorDetail!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (_status == _ExchangeStatus.failed)
                FilledButton(
                  onPressed: () => context.go(AppRoutes.email),
                  child: const Text('Back to Email settings'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ExchangeStatus { exchanging, success, failed }
