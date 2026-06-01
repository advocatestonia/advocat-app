// check-company SSRF guard
// -----------------------------------------------------------------------------
// The ONLY value ever interpolated into a server-side scrape URL is the registry
// code, host-pinned to ariregister.rik.ee. An Estonian registry code is 4–12
// digits; anything else (path traversal, host-injection, letters, empty) MUST
// NOT reach fetch(). Kept in its own module so the test can import the invariant
// without booting the serve() handler in index.ts.
// -----------------------------------------------------------------------------

export function isSafeRegistryCode(code: unknown): boolean {
  return typeof code === "string" && /^\d{4,12}$/.test(code);
}
