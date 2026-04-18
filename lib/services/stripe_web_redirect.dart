// Conditional import: uses JS interop on web, stubs on other platforms.

export 'stripe_web_redirect_stub.dart'
    if (dart.library.js_interop) 'stripe_web_redirect_impl.dart';
