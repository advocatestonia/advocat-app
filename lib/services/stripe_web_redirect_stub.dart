/// Stub for non-web platforms. Should never be called because the caller
/// gates on [kIsWeb], but provided for compilation safety.
void redirectToUrl(String url) {
  throw UnsupportedError('redirectToUrl is only supported on web');
}
