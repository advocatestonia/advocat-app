// _shared/auditLog.ts
// -----------------------------------------------------------------------------
// Append-only org audit log helper. GDPR Art. 30 evidence — every privileged
// action against an org (invite, role change, removal, billing, API keys)
// must produce an audit row.
//
// Failure-tolerant by design: an audit-log failure must NEVER break the
// caller's main flow. The helper logs to console.error and returns; callers
// don't need a try/catch.
//
// Usage:
//   await writeOrgAudit(supabase, {
//     org_id: ctx.org_id,
//     actor_user_id: ctx.user_id,
//     action: "member_invited",
//     details: { email, role },
//     req,
//   });
// -----------------------------------------------------------------------------

export type OrgAuditAction =
  | "org_created"
  | "org_updated"
  | "org_deleted"
  | "member_invited"
  | "member_joined"
  | "member_removed"
  | "role_changed"
  | "ownership_transferred"
  | "checkout_started"
  | "subscription_updated"
  | "seats_purchased"
  | "api_key_created"
  | "api_key_revoked"
  | "case_shared"
  | "data_exported"
  | "billing_portal_opened";

export interface OrgAuditArgs {
  org_id: string;
  actor_user_id: string;
  action: OrgAuditAction;
  /** UUID of the target user (member changes), or null. */
  target_user_id?: string | null;
  /** e.g. "case" / "document" / "api_key". */
  target_resource_type?: string | null;
  /** UUID of the target resource. */
  target_resource_id?: string | null;
  /** Free-form structured payload. Keep small — DB row size matters. */
  details?: Record<string, unknown>;
  /** The incoming Request, for IP + UA extraction. Optional. */
  req?: Request;
}

/** Write one row to org_audit_log. Errors are logged, never thrown. */
export async function writeOrgAudit(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  args: OrgAuditArgs,
): Promise<void> {
  try {
    const ip = args.req ? extractClientIp(args.req) : null;
    const ua = args.req ? (args.req.headers.get("user-agent") ?? "").slice(0, 500) : null;

    const { error } = await supabase.from("org_audit_log").insert({
      org_id: args.org_id,
      actor_user_id: args.actor_user_id,
      action: args.action,
      target_user_id: args.target_user_id ?? null,
      target_resource_type: args.target_resource_type ?? null,
      target_resource_id: args.target_resource_id ?? null,
      details: args.details ?? {},
      ip,
      user_agent: ua,
    });

    if (error) {
      // Logging only — caller's main flow continues.
      console.error(
        `[auditLog] insert failed action=${args.action} org=${args.org_id}: ${error.message}`,
      );
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(
      `[auditLog] unexpected error action=${args.action}: ${msg.slice(0, 200)}`,
    );
  }
}

function extractClientIp(req: Request): string | null {
  const cf = req.headers.get("cf-connecting-ip");
  if (cf && cf.trim()) return cf.trim();
  const xff = req.headers.get("x-forwarded-for") ?? "";
  const first = xff.split(",")[0]?.trim();
  return first || null;
}
