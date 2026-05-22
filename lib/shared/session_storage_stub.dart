// Stub for non-web platforms. The Riverpod state is the source of truth
// off-web, so reads/writes are no-ops. Provided so conditional imports
// can resolve at compile time on iOS/Android/desktop targets.
//
// See [SessionStorage] below for the contract.

class SessionStorage {
  static String? read(String key) => null;
  static void write(String key, String value) {}
  static void remove(String key) {}
}
