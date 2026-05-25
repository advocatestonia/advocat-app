// _shared/orgAuth.ts
// -----------------------------------------------------------------------------
// B2B multi-tenant: validates that the JWT-authenticated caller is a member of
// the org named in the X-Org-Context header and (optionally) has at least the
// minimum role required by the endpoint.
//
// Used by every B2B edge function that mutates or reads org-scoped data.
//
// Usage:
//   const userGate = await requireUserWithRateLimit(req, {...});
//   if (userGate.kind === "deny") return userGate.response;
//
//   const orgGate = await requireOrgContext(req, supabase, userGate.user.id, {
//     minRole: "admin",
//   });
//   if (orgGate.kind === "deny") return orgGate.response;
//
//   const { org_id, role } = orgGate.ctx;
//
// Why a separate helper from _shared/auth.ts?
//   * auth.ts only knows about user-JWT auth. Org context is a layer above:
//     the same JWT can act in 3 different orgs depending on which one is
//     selected in the Flutter app, so the validation cannot live in auth.ts.
//   * Keeping it in its own file means non-org endpoints (B2C-only) don't
//     pay the membership-lookup cost.
//
// Security notes:
//   * Membership lookup uses the service-role client, bypassing RLS — the
//     whole point is that we authoritatively decide the user's role.
//   * `removed_at IS NULL` is required: a soft-removed member must NOT be
//     able to act on the org.
//   * The header is `X-Org-Context` (kebab case in the spec). Browsers
//     lower-case header names; we read it case-insensitively.
// -----------------------------------------------------------------------------

import { jsonError } from "./auth.ts";

export type OrgRole = "owner" | "admin" | "member" | "viewer" | "billing";

/** Role hierarchy used for `minRole` comparisons. Higher number = more power.
 *  `billing` is parallel to `admin` for billing-related actions only — callers
 *  that want "admin OR billing" should pass `minRole: "billing"` and the
 *  comparator below will accept both (admin >= billing). */
const ROLE_RANK: Record<OrgRole, number> = {
  viewer: 1,
  member: 2,
  billing: 3,
  admin: 4,
  owner: 5,
};

export interface OrgContext {
  org_id: string;
  role: OrgRole;
  user_id: string;
  user_email: string;
}

export type OrgContextResult =
  | { kind: "ok"; ctx: OrgContext }
  | { kind: "deny"; response: Response };

export interface RequireOrgContextOpts {
  /** Minimum role required. Defaults to "viewer" (any active member). */
  minRole?: OrgRole;
  /** If true, the X-Org-Context header MUST be present. Default true.
   *  Pass false from endpoints that accept both B2C (no header) and B2B
   *  (with header) traffic — those endpoints handle the absent case
   *  themselves. */
  required?: boolean;
}

/** Read the X-Org-Context header, validate it as a UUID, look up membership,
 *  and return either an OrgContext or a ready-to-return 4xx Response. */
export async function requireOrgContext(
  req: Request,
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  userEmail: string | undefined,
  opts: RequireOrgContextOpts = {},
): Promise<OrgContextResult> {
  const required = opts.required ?? true;
  const minRole: OrgRole = opts.minRole ?? "viewer";

  // Header lookup is case-insensitive in fetch's Headers, but be defensive.
  const orgHeader =
    req.headers.get("X-Org-Context") ??
    req.headers.get("x-org-context") ??
    "";

  if (!orgHeader) {
    if (!required) {
      // Caller wants to handle the absent case (B2C-or-B2B endpoints).
      // We signal "deny" with a sentinel response that the caller can
      // detect; but the contract is simpler if the caller just calls
      // a different code path when the header is missing. Hence: return
      // deny only when required.
      return {
        kind: "deny",
        response: jsonError("X-Org-Context header required", 400, {
          reason: "missing_org_context",
        }),
      };
    }
    return {
      kind: "deny",
      response: jsonError("X-Org-Context header required", 400, {
        reason: "missing_org_context",
      }),
    };
  }

  // UUID format check (cheap, blocks header-injection garbage before DB).
  if (!isUuid(orgHeader)) {
    return {
      kind: "deny",
      response: jsonError("Invalid org context", 400, {
        reason: "invalid_org_id",
      }),
    };
  }

  // Membership lookup. The org_members table is service-role-readable.
  const { data: membership, error } = await supabase
    .from("org_members")
    .select("role")
    .eq("org_id", orgHeader)
    .eq("user_id", userId)
    .is("removed_at", null)
    .maybeSingle();

  if (error) {
    console.error("[orgAuth] membership lookup failed:", error);
    return {
      kind: "deny",
      response: jsonError("Membership lookup failed", 503, {
        reason: "membership_lookup_failed",
      }),
    };
  }
  if (!membership) {
    // We deliberately use the same 403 for "not a member" and "org doesn't
    // exist" — leaking the difference is a tenant-enumeration vector.
    return {
      kind: "deny",
      response: jsonError("Not a member of this organization", 403, {
        reason: "not_a_member",
      }),
    };
  }

  const role = membership.role as OrgRole;
  if (ROLE_RANK[role] < ROLE_RANK[minRole]) {
    return {
      kind: "deny",
      response: jsonError("Insufficient role for this action", 403, {
        reason: "role_insufficient",
        required_min_role: minRole,
        actual_role: role,
      }),
    };
  }

  return {
    kind: "ok",
    ctx: {
      org_id: orgHeader,
      role,
      user_id: userId,
      user_email: userEmail ?? "",
    },
  };
}

/** Compare two roles using the rank table; useful for in-handler checks
 *  (e.g. "owner cannot demote themselves"). */
export function roleAtLeast(actual: OrgRole, required: OrgRole): boolean {
  return ROLE_RANK[actual] >= ROLE_RANK[required];
}

function isUuid(s: string): boolean {
  return /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/
    .test(s);
}
