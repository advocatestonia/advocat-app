// gmail-label/labels.ts
// -----------------------------------------------------------------------------
// Pure label-domain helpers. Extracted from `index.ts` so tests can
// import them without booting the `serve()` HTTP listener.
// -----------------------------------------------------------------------------

const LABEL_NAME_MAX = 100;
const SYSTEM_LABELS = new Set([
  "INBOX", "UNREAD", "STARRED", "IMPORTANT", "TRASH", "SPAM",
  "DRAFT", "SENT", "CHAT",
  "CATEGORY_PERSONAL", "CATEGORY_SOCIAL", "CATEGORY_PROMOTIONS",
  "CATEGORY_UPDATES", "CATEGORY_FORUMS",
]);

/** Hex-ish gmail thread id from the client (not the trusted DB column). */
export function sanitiseThreadId(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const s = v.trim();
  if (s.length === 0 || s.length > 200) return null;
  if (!/^[A-Za-z0-9_\-]+$/.test(s)) return null;
  return s;
}

/** UUID v4-ish — what the client passes as `thread_id`. */
export function sanitiseUuid(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const s = v.trim().toLowerCase();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(s)) {
    return null;
  }
  return s;
}

/** Server-trusted gmail_thread_id (came from email_threads.gmail_thread_id). */
export function sanitiseGmailThreadId(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const s = v.trim();
  if (s.length === 0 || s.length > 200) return null;
  if (!/^[A-Za-z0-9_\-]+$/.test(s)) return null;
  return s;
}

export function sanitiseLabels(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  const out: string[] = [];
  for (const raw of v) {
    if (typeof raw !== "string") continue;
    const trimmed = raw.trim();
    if (trimmed.length === 0 || trimmed.length > LABEL_NAME_MAX) continue;
    // Block control chars + line breaks in label names. Slashes are
    // allowed (Gmail uses them for nested labels).
    if (/[\x00-\x1F\x7F]/.test(trimmed)) continue;
    out.push(trimmed);
  }
  return Array.from(new Set(out));
}

export interface ApplyArgs {
  accessToken: string;
  threadId: string;
  addLabels: string[];
  removeLabels: string[];
}

export interface ApplyResult {
  applied: string[];
  removed: string[];
  labelIds: Record<string, string>;
}

/**
 * Apply add/remove labels to a Gmail thread. Custom labels that don't
 * exist yet are auto-created (Gmail policy: labels.create). System
 * labels are passed through by name (Gmail accepts them as ids
 * directly: INBOX/UNREAD/etc.).
 */
export async function applyLabels(args: ApplyArgs): Promise<ApplyResult> {
  const labelIds: Record<string, string> = {};
  for (const name of [...args.addLabels, ...args.removeLabels]) {
    labelIds[name] = await resolveLabelId(args.accessToken, name);
  }
  const addIds = args.addLabels.map((n) => labelIds[n]).filter(Boolean);
  const removeIds = args.removeLabels.map((n) => labelIds[n]).filter(Boolean);

  const url =
    `https://gmail.googleapis.com/gmail/v1/users/me/threads/${
      encodeURIComponent(args.threadId)
    }/modify`;
  const resp = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${args.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      addLabelIds: addIds,
      removeLabelIds: removeIds,
    }),
  });
  if (!resp.ok) {
    const detail = await resp.text();
    throw new Error(
      `gmail threads.modify ${resp.status}: ${detail.slice(0, 200)}`,
    );
  }
  return {
    applied: args.addLabels,
    removed: args.removeLabels,
    labelIds,
  };
}

/**
 * Resolve a label name to its Gmail id. System labels (INBOX, UNREAD,
 * etc.) round-trip as their own name. Custom labels are looked up via
 * users.labels.list and created if missing.
 *
 * Soft-fail: throws on any non-OK Gmail response so the caller can wrap
 * the whole pipeline in a single try/catch (the serve() handler returns
 * 200 + error_code on those throws).
 */
export async function resolveLabelId(
  accessToken: string,
  labelName: string,
): Promise<string> {
  if (SYSTEM_LABELS.has(labelName)) return labelName;

  const listResp = await fetch(
    "https://gmail.googleapis.com/gmail/v1/users/me/labels",
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (!listResp.ok) {
    const detail = await listResp.text();
    throw new Error(
      `gmail labels.list ${listResp.status}: ${detail.slice(0, 200)}`,
    );
  }
  const listData = await listResp.json();
  const labels = (listData?.labels ?? []) as Array<{ id?: string; name?: string }>;
  const found = labels.find(
    (l) => l.name === labelName && typeof l.id === "string",
  );
  if (found?.id) return found.id;

  const createResp = await fetch(
    "https://gmail.googleapis.com/gmail/v1/users/me/labels",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: labelName,
        labelListVisibility: "labelShow",
        messageListVisibility: "show",
      }),
    },
  );
  if (!createResp.ok) {
    const detail = await createResp.text();
    throw new Error(
      `gmail labels.create ${createResp.status}: ${detail.slice(0, 200)}`,
    );
  }
  const created = await createResp.json();
  if (typeof created?.id !== "string") {
    throw new Error("gmail labels.create returned no id");
  }
  return created.id;
}
