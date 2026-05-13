// consilium_roles/memory.ts — reads project memory files into role prompts.
// -----------------------------------------------------------------------------
// Each Domain/Strategic role can declare a `memoryHooks: ["lesson_xxx.md"]`
// list. At prompt-compile time, this module reads those files (if present)
// and concatenates their bodies into a single "<memory>…</memory>" block that
// the role's systemPromptFactory can embed.
//
// Path resolution:
//   1. CONSILIUM_MEMORY_DIR env var (test override)
//   2. USER_HOME env var → $USER_HOME/.claude/projects/-Users-ai-place-Advocat/memory/
//   3. Hard-coded host path /Users/ai.place/.claude/projects/-Users-ai-place-Advocat/memory/
//
// In edge-fn production, the memory dir typically isn't bundled. The loader
// returns "" silently in that case — roles still work, just without the
// auto-injected lessons. (Production prompts can preload key lessons via the
// chat layer's case_context if needed.)
//
// Caps: each file is truncated to 4 KB to avoid blowing system-prompt budget.
// -----------------------------------------------------------------------------

const PER_FILE_CAP = 4096;
const TOTAL_CAP = 24_576; // 24 KB total memory budget across hooks

/** Reader interface so tests can inject an in-memory fake. */
export interface MemoryReader {
  read(filename: string): Promise<string | null>;
}

/** Default Deno-based reader. Returns null on ENOENT / permission errors. */
export class DenoMemoryReader implements MemoryReader {
  constructor(private readonly baseDir: string) {}

  async read(filename: string): Promise<string | null> {
    // Defensive against path-traversal — only allow plain filenames.
    if (filename.includes("/") || filename.includes("..")) {
      return null;
    }
    try {
      const full = `${this.baseDir.replace(/\/$/, "")}/${filename}`;
      // @ts-ignore Deno global is fine in Supabase edge runtime + deno test.
      const text = await Deno.readTextFile(full);
      return text;
    } catch (_e) {
      return null;
    }
  }
}

/** In-memory reader used by tests. */
export class StubMemoryReader implements MemoryReader {
  constructor(private readonly files: Record<string, string>) {}
  async read(filename: string): Promise<string | null> {
    return this.files[filename] ?? null;
  }
}

/** Resolve the default base dir from env. */
export function resolveDefaultMemoryDir(): string {
  // @ts-ignore Deno global.
  const env = typeof Deno !== "undefined" ? Deno.env : null;
  const override = env?.get?.("CONSILIUM_MEMORY_DIR");
  if (override) return override;
  const home = env?.get?.("USER_HOME");
  if (home) {
    return `${home}/.claude/projects/-Users-ai-place-Advocat/memory`;
  }
  return "/Users/ai.place/.claude/projects/-Users-ai-place-Advocat/memory";
}

/** Read a list of memory files and return a single XML-tagged blob. Returns
 *  the empty string if all hooks are missing — callers should treat this as
 *  "no memory available, proceed without". */
export async function loadMemoryHooks(
  hooks: readonly string[] | undefined,
  reader: MemoryReader,
): Promise<string> {
  if (!hooks || hooks.length === 0) return "";

  const blobs: string[] = [];
  let totalBytes = 0;

  for (const hook of hooks) {
    const body = await reader.read(hook);
    if (!body) continue;
    // Strip YAML front-matter so the prompt sees only the lesson body.
    const stripped = stripFrontMatter(body).trim();
    if (!stripped) continue;
    const clipped = stripped.length > PER_FILE_CAP
      ? stripped.slice(0, PER_FILE_CAP) + "\n…(truncated)"
      : stripped;
    const block = `<memory_lesson file="${hook}">\n${clipped}\n</memory_lesson>`;
    if (totalBytes + block.length > TOTAL_CAP) break;
    blobs.push(block);
    totalBytes += block.length;
  }

  if (blobs.length === 0) return "";
  return `<memory>\n${blobs.join("\n\n")}\n</memory>`;
}

/** Drop the leading `---…---` YAML block if present. */
function stripFrontMatter(body: string): string {
  if (!body.startsWith("---")) return body;
  const end = body.indexOf("\n---", 3);
  if (end === -1) return body;
  return body.slice(end + 4);
}
