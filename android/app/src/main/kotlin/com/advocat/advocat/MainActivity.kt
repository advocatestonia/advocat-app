package com.advocat.advocat

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity hosts the Flutter engine and exposes the `advocat/secure_screen`
 * platform channel that lets Dart toggle Android's `WindowManager.LayoutParams.FLAG_SECURE`
 * on the host window.
 *
 * Why this exists — WAVE 2 FIX W2-03 (2026-05-28)
 * -----------------------------------------------
 * Security audit finding F3 (`docs/security_audit_2026-05-28/findings/03_client_security.md`)
 * flagged that 13 confidentially-classed Flutter screens (Vault, Drafting Studio,
 * Contract Review, Chat, Inbox, Case Workspace, Intake Wizard, Email, Case File,
 * Firm/B2B, Login/Register, AI Memory, Legal-Aid Calculator, Admin Gold Review)
 * had no FLAG_SECURE protection. That means:
 *
 *   * Accessibility-service / screen-recorder malware can capture the screen.
 *   * Foreground recording (MediaProjection) can capture the screen.
 *   * The Recents/Overview snapshot leaks the last legal-content frame to
 *     whoever opens the App Switcher next on a shared device.
 *
 * Setting `FLAG_SECURE` on the window:
 *   * blocks screenshots (the screenshot button silently fails or shows a
 *     "blocked by app" toast on modern Android),
 *   * blocks screen recording,
 *   * replaces the Recents snapshot with a blank surface.
 *
 * We expose the toggle as a MethodChannel rather than wiring it once at app
 * startup because not every screen is confidential — the Onboarding flow,
 * marketing screens, and public Rights browser deliberately stay unsecured so
 * users can screenshot referral codes / share legal info. The matrix of which
 * screens are protected lives in finding 03 ("FLAG_SECURE Recommendation
 * Matrix") and is enforced from Dart via SecureScreenScope.
 *
 * Reference counting
 * ------------------
 * The Dart side already ref-counts so we do not have to here — `setSecure`
 * always sets the flag, `clearSecure` always clears it. Idempotent operations
 * keep the platform contract simple and easy to test.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val SECURE_SCREEN_CHANNEL = "advocat/secure_screen"
        private const val METHOD_SET_SECURE = "setSecure"
        private const val METHOD_CLEAR_SECURE = "clearSecure"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURE_SCREEN_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_SET_SECURE -> {
                    runOnUiThread {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                METHOD_CLEAR_SECURE -> {
                    runOnUiThread {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // We intentionally do NOT set FLAG_SECURE at startup. The flag is
        // toggled per-screen by Dart's SecureScreenScope so the public-facing
        // screens (Onboarding, Landmarks, Rights, Referral Landing, marketing
        // surfaces) remain screenshot-friendly.
    }
}
