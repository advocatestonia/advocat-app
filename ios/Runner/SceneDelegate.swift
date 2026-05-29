import Flutter
import UIKit

/// SceneDelegate installs the App-Switcher blur overlay that protects
/// counsel-attorney privileged content from the Recents snapshot leak on iOS.
///
/// Why this exists — WAVE 2 FIX W2-03 (2026-05-28)
/// -----------------------------------------------
/// iOS captures a snapshot of every scene as it resigns active (this is what
/// you see when you swipe up to the App Switcher). The snapshot is stored on
/// disk in the app's sandbox and is the LAST visible frame before backgrounding.
///
/// For a legal-tech app that surfaces:
///   * Vault documents (privileged client material),
///   * Drafting Studio (in-progress privileged drafts),
///   * Contract Review red flags,
///   * Case Workspace facts + deadlines,
///   * Inbox email content,
///   * Chat with counsel,
///   * Intake Wizard live client facts,
///
/// leaving that snapshot intact violates the EU bar association rule that
/// privileged material must not be accessible to "any person other than the
/// client, attorney, or duly authorised representative" (cf. NY bar Op. 1019
/// and EE Advokatuur eetikakoodeks §5.2).
///
/// Solution
/// --------
/// On `sceneWillResignActive`, if `SecureScreenState.shared.isSecure == true`
/// (set by Dart via the SecureScreenScope wrapping a confidential screen),
/// we cover the key window with an opaque blur view. iOS then snapshots THAT
/// view instead of the real UI. On `sceneDidBecomeActive` we remove the blur.
///
/// We also subscribe to `UIApplication.userDidTakeScreenshotNotification` so
/// future audit work can log "user screenshotted while viewing confidential
/// content" — iOS does not allow blocking the screenshot, but we can detect
/// and record it.
class SceneDelegate: FlutterSceneDelegate {

  private var blurView: UIVisualEffectView?
  private var screenshotObserver: NSObjectProtocol?

  override func sceneDidDisconnect(_ scene: UIScene) {
    super.sceneDidDisconnect(scene)
    if let observer = screenshotObserver {
      NotificationCenter.default.removeObserver(observer)
      screenshotObserver = nil
    }
  }

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    // Register a screenshot observer once per scene so audit logs in a
    // future iteration can mark "user took a screenshot of confidential
    // content". Today this is a no-op hook — wiring to telemetry is owner-
    // scoped because it crosses the consent gate.
    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { _ in
      // Intentionally empty. Hook left in place for a future "screenshot
      // taken while secure-screen active" telemetry event. We do NOT log
      // anything PII-shaped here.
      _ = SecureScreenState.shared.isSecure
    }
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    guard SecureScreenState.shared.isSecure else { return }
    attachBlurOverlay(scene: scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    removeBlurOverlay()
  }

  /// Attach an opaque blur overlay to the key window of the given scene.
  /// We intentionally use `.systemMaterial` (a heavy blur) plus a solid
  /// background tint so the snapshot stored on disk is unreadable even if
  /// the blur layer ends up partially transparent in some iOS variants.
  private func attachBlurOverlay(scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    guard let window = windowScene.windows.first(where: { $0.isKeyWindow })
              ?? windowScene.windows.first else { return }

    if blurView != nil { return }

    let effect = UIBlurEffect(style: .systemMaterial)
    let view = UIVisualEffectView(effect: effect)
    view.frame = window.bounds
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    // Fallback opaque tint in case the blur is not honoured (e.g. Reduce
    // Transparency accessibility setting). Use the app's launch background
    // so the blur reads as "Advocat is locked" rather than "the app crashed".
    view.backgroundColor = UIColor(white: 0.08, alpha: 1.0)

    window.addSubview(view)
    blurView = view
  }

  private func removeBlurOverlay() {
    blurView?.removeFromSuperview()
    blurView = nil
  }
}
