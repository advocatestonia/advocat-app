// Stub for non-web platforms. The web_streaming_impl.dart uses dart:js_interop
// which is only available on web, so this stub is imported on mobile/desktop.

/// Stub — throws on non-web platforms (should never be called because
/// claude_service.dart gates on kIsWeb before calling this).
Stream<String> webSendMessageStreaming({
  required String url,
  required String bodyJson,
  required String authToken,
  required String apiKey,
}) {
  throw UnsupportedError('webSendMessageStreaming is only available on web');
}
