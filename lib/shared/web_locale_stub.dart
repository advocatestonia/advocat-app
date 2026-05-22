/// Non-web stub for landing/browser locale bridge.
///
/// On native platforms there is no `window`/`navigator`/`localStorage`,
/// so both helpers return `null` and the caller falls through to the
/// next priority step (SharedPreferences or the Estonian default).
///
/// The matching web implementation lives in `web_locale_web.dart` and is
/// picked up via a conditional import on `dart.library.html`.
String? readLandingLang() => null;

String? readNavigatorLang() => null;
