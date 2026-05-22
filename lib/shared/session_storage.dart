// Conditional re-export: window.sessionStorage on web, no-op stub elsewhere.
//
// Used by [PendingCheckoutNotifier] to persist the pending checkout across
// the Stripe redirect → return bounce so a slow auth or a hard refresh on
// the success page doesn't lose the user's intent.

export 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart';
