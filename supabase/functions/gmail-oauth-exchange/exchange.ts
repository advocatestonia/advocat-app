// gmail-oauth-exchange/exchange.ts
// -----------------------------------------------------------------------------
// Pure body builder for the OAuth code-exchange POST. Lives outside
// index.ts so it can be unit-tested without the `serve()` side-effect.
//
// Google's documented exchange contract:
//   POST https://oauth2.googleapis.com/token
//   Content-Type: application/x-www-form-urlencoded
//   Body:
//     grant_type=authorization_code
//     code=<auth-code-from-redirect>
//     client_id=<GOOGLE_CLIENT_ID>
//     client_secret=<GOOGLE_CLIENT_SECRET>
//     redirect_uri=<must match the redirect_uri sent at init>
//
// Returns a `URLSearchParams` so the caller can `.toString()` it for the
// fetch body. URLSearchParams handles percent-encoding for us — any code
// containing `+`, `/`, or other reserved chars is encoded safely.
// -----------------------------------------------------------------------------

export interface BuildExchangeBodyArgs {
  code: string;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
}

export function buildExchangeBody(args: BuildExchangeBodyArgs): URLSearchParams {
  const p = new URLSearchParams();
  p.set("grant_type", "authorization_code");
  p.set("code", args.code);
  p.set("client_id", args.clientId);
  p.set("client_secret", args.clientSecret);
  p.set("redirect_uri", args.redirectUri);
  return p;
}
