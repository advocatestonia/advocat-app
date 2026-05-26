#!/usr/bin/env python3
"""
reconnect_gmail_users.py — one-shot helper to reconnect 5 prod users whose
user_oauth_tokens.refresh_token is NULL.

ROOT CAUSE: Supabase gotrue swallows access_type=offline + prompt=consent
when forwarding OAuth to Google. Google then omits refresh_token. Sync
silently skips these users every 15 min.

FIX: bypass Supabase Auth, do direct Google OAuth flow per user:
  1. Generate an authorize URL with access_type=offline + prompt=consent
  2. Owner clicks the URL, signs in as the user, copies redirect URL
  3. Script extracts authorization code, exchanges for token-pair via
     Google's token endpoint directly (GOOGLE_CLIENT_ID + SECRET).
  4. Upsert user_oauth_tokens row with refresh_token + scope + expires_at.

USAGE
    cd /Users/ai.place/Advocat/app/advocat_project
    GOOGLE_CLIENT_ID=... GOOGLE_CLIENT_SECRET=... \
    SUPABASE_ACCESS_TOKEN=... \
    python3 scripts/reconnect_gmail_users.py --list      # show affected users
    python3 scripts/reconnect_gmail_users.py --user-id <uuid>  # reconnect one
    python3 scripts/reconnect_gmail_users.py --all       # interactive batch

REDIRECT URI — must be set in Google Cloud Console for the OAuth client:
    https://advocat.ee/oauth/gmail/return
The redirect lands on a static page (or Flutter route) that just echoes
back ?code=XXX in the URL. The script asks you to paste that URL.

This is a TEMPORARY one-off until the in-app gmail-oauth-init + exchange
edge fns + Flutter UI ship (Phase 2a — separate task).
"""
import argparse
import json
import os
import sys
import urllib.parse
import urllib.request
from typing import Any

PROJECT_REF = "okgnkucgwsytsondrjye"
REDIRECT_URI = "https://advocat.ee/oauth/gmail/return"
SCOPE = " ".join([
    "email",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.modify",
])
GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"


def env(name: str) -> str:
    v = os.environ.get(name, "").strip()
    if not v:
        sys.exit(f"ERROR: env var {name} required")
    return v


def mgmt_query(sql: str) -> Any:
    """Run SQL via Supabase Management API."""
    token = env("SUPABASE_ACCESS_TOKEN")
    body = json.dumps({"query": sql}).encode()
    req = urllib.request.Request(
        f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query",
        data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "advocat-reconnect-gmail/1.0",
            "Accept": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def list_affected() -> list[dict]:
    """List Gmail OAuth rows where refresh_token IS NULL (sync-broken)."""
    rows = mgmt_query("""
        SELECT user_id, email, created_at, expires_at
        FROM public.user_oauth_tokens
        WHERE provider = 'gmail' AND refresh_token IS NULL
        ORDER BY created_at DESC;
    """)
    return rows or []


def build_authorize_url(state: str) -> str:
    """Build the Google OAuth authorize URL with offline+consent flags."""
    qs = urllib.parse.urlencode({
        "client_id": env("GOOGLE_CLIENT_ID"),
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": SCOPE,
        "access_type": "offline",
        "prompt": "consent",
        "state": state,
    })
    return f"{GOOGLE_AUTH_URL}?{qs}"


def exchange_code(code: str) -> dict:
    """POST the authorization code to Google's token endpoint."""
    body = urllib.parse.urlencode({
        "code": code,
        "client_id": env("GOOGLE_CLIENT_ID"),
        "client_secret": env("GOOGLE_CLIENT_SECRET"),
        "redirect_uri": REDIRECT_URI,
        "grant_type": "authorization_code",
    }).encode()
    req = urllib.request.Request(
        GOOGLE_TOKEN_URL,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err_body = e.read().decode(errors="replace")
        sys.exit(f"Google token exchange failed: {e.code} {err_body}")


def email_from_id_token(id_token: str) -> str | None:
    """Decode the email claim from a Google id_token (JWT middle segment)."""
    try:
        parts = id_token.split(".")
        if len(parts) != 3:
            return None
        padded = parts[1] + "=" * (-len(parts[1]) % 4)
        import base64
        payload = json.loads(base64.urlsafe_b64decode(padded))
        return payload.get("email")
    except Exception:
        return None


def upsert_token(user_id: str, token_data: dict, email: str | None) -> None:
    """Upsert user_oauth_tokens with the fresh token-pair."""
    import time
    expires_at = (
        f"now() + interval '{int(token_data.get('expires_in', 3600))} seconds'"
    )
    # Embed values inline (escaped) — Management API only accepts a single
    # SQL string; we don't have parameterised execute here. We URL-quote the
    # tokens via the safe set [A-Za-z0-9._\-/+=] which Google tokens use.
    def safe(s: str) -> str:
        # SQL literal escape (single-quote double, no concat)
        return s.replace("'", "''")

    access_token = safe(token_data["access_token"])
    refresh_token = safe(token_data["refresh_token"])
    scope = safe(token_data.get("scope", SCOPE))
    email_sql = f"'{safe(email)}'" if email else "NULL"

    sql = f"""
        INSERT INTO public.user_oauth_tokens
            (user_id, provider, access_token, refresh_token, email, expires_at, scope, updated_at)
        VALUES
            ('{user_id}', 'gmail', '{access_token}', '{refresh_token}', {email_sql}, {expires_at}, '{scope}', now())
        ON CONFLICT (user_id, provider) DO UPDATE SET
            access_token  = EXCLUDED.access_token,
            refresh_token = EXCLUDED.refresh_token,
            email         = COALESCE(EXCLUDED.email, public.user_oauth_tokens.email),
            expires_at    = EXCLUDED.expires_at,
            scope         = EXCLUDED.scope,
            updated_at    = now();
    """
    mgmt_query(sql)


def reconnect_one(user_id: str, email_hint: str | None) -> None:
    print(f"\n=== Reconnecting {user_id} ({email_hint or 'no email on file'}) ===")
    state = f"reconnect-{user_id[:8]}"
    auth_url = build_authorize_url(state)
    print("\n1. Open this URL in a browser and sign in as the affected user:\n")
    print(f"   {auth_url}\n")
    print("2. After consent Google redirects to:")
    print(f"   {REDIRECT_URI}?code=XXX&state={state}")
    print(
        "   (advocat.ee may show 404 — that's fine, just copy the URL from the address bar)\n",
    )
    redirect_url = input("3. Paste the full redirect URL here: ").strip()
    parsed = urllib.parse.urlparse(redirect_url)
    params = urllib.parse.parse_qs(parsed.query)
    code_list = params.get("code")
    state_back = params.get("state", [""])[0]
    if not code_list:
        sys.exit("No ?code= in URL — aborting")
    if state_back != state:
        sys.exit(f"state mismatch: expected {state} got {state_back}")
    code = code_list[0]
    print(f"\n4. Exchanging code with Google ({len(code)} char) ...")
    data = exchange_code(code)
    if "refresh_token" not in data:
        sys.exit(
            f"Google omitted refresh_token. Response keys: {list(data.keys())}\n"
            "Try revoking access at https://myaccount.google.com/permissions, "
            "then retry."
        )
    email = email_from_id_token(data.get("id_token", "")) or email_hint
    print(f"5. Got refresh_token ({len(data['refresh_token'])} char), email={email}")
    print("6. Upserting user_oauth_tokens ...")
    upsert_token(user_id, data, email)
    print("✅ Done. Cron sync will pick this user up on the next tick.")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--list", action="store_true", help="show affected users")
    g.add_argument("--user-id", help="reconnect one user (uuid)")
    g.add_argument("--all", action="store_true", help="reconnect all affected (interactive)")
    args = ap.parse_args()

    if args.list:
        rows = list_affected()
        if not rows:
            print("No users with NULL refresh_token. Nothing to do.")
            return
        print(f"Found {len(rows)} users to reconnect:\n")
        for r in rows:
            print(f"  {r['user_id']}  email={r.get('email')}  created={r.get('created_at')}")
        return

    if args.user_id:
        rows = list_affected()
        row = next((r for r in rows if r["user_id"] == args.user_id), None)
        if not row:
            sys.exit(f"user {args.user_id} is not in the affected set "
                     "(already has refresh_token, or not connected at all)")
        reconnect_one(args.user_id, row.get("email"))
        return

    if args.all:
        rows = list_affected()
        if not rows:
            print("No users to reconnect.")
            return
        print(f"About to reconnect {len(rows)} users one-by-one.\n")
        for r in rows:
            try:
                reconnect_one(r["user_id"], r.get("email"))
            except KeyboardInterrupt:
                print("\nAborted by user.")
                sys.exit(1)
            except SystemExit as e:
                print(f"Skipping {r['user_id']} — {e}")
                continue


if __name__ == "__main__":
    main()
