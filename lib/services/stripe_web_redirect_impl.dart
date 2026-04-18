import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Redirects the current browser page to [url] using JS interop.
void redirectToUrl(String url) {
  (globalContext['location'] as JSObject)
      .setProperty('href'.toJS, url.toJS);
}
