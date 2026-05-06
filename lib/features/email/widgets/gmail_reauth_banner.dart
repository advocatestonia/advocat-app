// gmail_reauth_banner.dart — D1 re-auth banner for users on V1 OAuth scopes.
// -----------------------------------------------------------------------------
// Shown above the "connected" view in EmailScreen when the user's stored
// Gmail token was minted with the V1 scope set (send-only) but the active
// flag (kGmailScopesActive) is V2 (send + readonly + modify). Tapping
// `Reauthorize` runs `connectGmail()` again, which forces `prompt=consent`
// and yields a fresh token with `gmail.readonly` + `gmail.modify`.
//
// Refs:
//   business/email_agent_handoff_2026-05-06/v2.1_consilium/CONSILIUM_DECISIONS.md §0
//   business/email_agent_handoff_2026-05-06/v2.1_consilium/track_C_owner_decisions.md O1
//   lib/config/feature_flags.dart
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// One-time banner shown to users who connected Gmail before D1 V2 scopes
/// shipped. The banner mounts above the existing `_ConnectedView` body and
/// disappears after the user re-runs OAuth (the next token write replaces
/// `user_oauth_tokens.scope` with the V2 scope string, which trips the
/// `gmailScopeIncludesReadonly` predicate).
class GmailReauthBanner extends StatelessWidget {
  const GmailReauthBanner({super.key, required this.onReauthorize});

  final VoidCallback onReauthorize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.gmailReauthBannerBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onReauthorize,
              child: Text(l10n.gmailReauthBannerCta),
            ),
          ],
        ),
      ),
    );
  }
}
