import Flutter
import UIKit

/// AppDelegate bootstraps the implicit Flutter engine, registers plugins, and
/// installs the `advocat/secure_screen` method channel.
///
/// Why this exists — WAVE 2 FIX W2-03 (2026-05-28)
/// -----------------------------------------------
/// Security audit finding F3 flagged that confidentially-classed screens
/// (Vault, Drafting Studio, Contract Review, Chat, etc.) had no screenshot or
/// App Switcher protection on iOS. iOS has no direct equivalent to Android's
/// `FLAG_SECURE`, so we use the documented workaround:
///
///   * On `sceneWillResignActive` (the moment iOS captures the App Switcher
///     snapshot), cover the key window with an opaque blur overlay.
///   * On `sceneDidBecomeActive`, remove the overlay.
///
/// The blur overlay is only attached when `SecureScreenState.shared.isSecure`
/// is true. That flag is toggled from Dart via the method channel installed
/// here, which mirrors the Android FLAG_SECURE toggle one-to-one.
///
/// Screenshot prevention
/// ---------------------
/// iOS will not block the user's own Side+Volume-Up screenshot — there is no
/// supported API for that, and trying to fight it draws app-store rejections.
/// What we DO prevent is the implicit Recents/App-Switcher snapshot leaking
/// counsel-attorney privileged content to the next person who opens the app
/// on a shared device. We also fire a notification (via
/// `UIApplication.userDidTakeScreenshotNotification` listener registered by
/// SceneDelegate) so we can tell the user a screenshot was taken — useful
/// for client-vault audit trails.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "advocat/secure_screen",
      binaryMessenger: engineBridge.binaryMessenger
    )

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "setSecure":
        SecureScreenState.shared.isSecure = true
        result(nil)
      case "clearSecure":
        SecureScreenState.shared.isSecure = false
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Process-global state tracking whether the foreground scene contains
/// confidential content. The SceneDelegate reads this on
/// `sceneWillResignActive` to decide whether to apply the App-Switcher blur.
///
/// Thread-safety: writes only happen on the main thread (the method channel
/// callback runs on the Flutter platform thread, which is the main UI thread
/// on iOS by default). Reads happen from SceneDelegate which is also main
/// thread. No locking needed.
final class SecureScreenState {
  static let shared = SecureScreenState()
  private init() {}

  /// True iff at least one SecureScreenScope is currently mounted on the
  /// Dart side. Ref-counting is handled in Dart so this is just a mirror of
  /// the most recent `setSecure` / `clearSecure` call.
  var isSecure: Bool = false
}
