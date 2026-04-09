// Conditional import: uses JS interop on web, stubs on other platforms.

export 'web_speech_stub.dart'
    if (dart.library.js_interop) 'web_speech_impl.dart';
