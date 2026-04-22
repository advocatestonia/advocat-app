# ФАЗА 7 — Parent repo cleanup

**Дата:** 2026-04-22 19:42 EEST
**Repo:** `/Users/ai.place/Advocat` (parent of submodule)
**Status:** ✅ DONE

## Parent-repo state before

- No `.gitignore` at all → every tool-generated dir showed as untracked
- Modified: `app/advocat_project` (submodule pointer at 5ada9f4, HEAD now at 9b44082)
- Untracked noise: `.claude-flow/`, `.swarm/`, `.playwright-mcp/` (152 entries),
  `.consilium-17042026/` (31 entries), `tests_overnight/`, 10 *.png screenshots,
  `app/src/.dart_tool/`, `app/src/build/`
- Untracked content (preserved, not touched): `business/*.pdf`, `business/ET/`,
  `business/RU/`, `business/grants/`, `business/outreach/`, `cases/ohvriabi-meeting/`,
  `docs/FROZEN_v24.1.md`, `docs/REGRESSION_SUITE.md`, `docs/overnight-reports/`,
  `docs/security/`, `investor/`

## Actions taken

### 1. Added `.gitignore` (new file)

```gitignore
# macOS
.DS_Store

# Claude Flow / MCP tooling artifacts (NOT project content)
.claude-flow/
.swarm/
.playwright-mcp/

# Agent working folders (ephemeral consilium outputs — not source of truth)
.consilium-*/

# Overnight test outputs (regenerable)
tests_overnight/

# Screenshots created during dev sessions (regenerable)
*.png

# Local IDE junk
.idea/
*.iml

# Old dev copy under app/src — build/analysis artifacts, not source of truth
app/src/.dart_tool/
app/src/.flutter-plugins-dependencies
app/src/backend/.dart_tool/
app/src/build/
app/src/.idea/
app/src/*.iml
```

### 2. Bumped submodule pointer

From: `5ada9f4 feat(v24.2.3): native Russian/English voices via ElevenLabs v3`
To:   `9b44082 merge: fix/ai-quality — attachments + adaptive length + grammar + copy button`

### 3. Commit on parent

```
bd3bb37 chore: bump submodule to post-merge state + add parent .gitignore
```

Parent has NO git remote configured (local-only), so nothing to push.

## What was NOT touched

- `business/` PDFs/HTML (investor decks, strategy canon, brand guidelines, grants, outreach) — user content
- `cases/ohvriabi-meeting/` — Sulga case materials
- `investor/` — investor outreach materials
- `docs/FROZEN_v24.1.md`, `docs/REGRESSION_SUITE.md`, `docs/security/`, `docs/overnight-reports/` — project docs
- `agents/`, `database/`, `documents/`, `laws/`, `evidence/` — existing tracked content

These stay exactly as owner left them. Owner can decide later whether to commit.

## Tracked files check

```bash
cd /Users/ai.place/Advocat && git ls-files | wc -l
```

No tracked `.DS_Store`, no tracked `.dart_tool/`, no tracked `*.png` screenshots.

## Parent repo final state

- HEAD: `bd3bb37` (new commit, local-only)
- `.gitignore`: now present
- Submodule: at post-merge pointer `9b44082`
- Untracked user content: preserved as-is
