---
name: sync-launchpad
description: Pulls the latest agents, rules, skills, and settings from the launchpad GitHub repo and updates the current project. Use to get the latest Coach improvements across all projects.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
argument-hint: "[optional: --dry-run to preview changes without applying]"
---

# Sync Launchpad

Pull the latest .claude/ configuration from the launchpad repo and update this project.

**Launchpad repo**: https://github.com/bajakota-cyber/claud-app-dev-launchpad

## Process

### Step 1: Check for --dry-run

If the user passed `--dry-run`, only report what would change. Do NOT apply any changes.

### Step 2: Determine where we are

Check if this IS the launchpad repo or a downstream project:

```bash
git remote get-url origin 2>/dev/null
```

- If the URL contains `claud-app-dev-launchpad` → **This is the launchpad repo itself**. Just run `git pull origin main` and you're done.
- If the URL is different or missing → **This is a downstream project**. Continue to Step 3.

### Step 3: Fetch the latest launchpad

Clone the launchpad to a temp directory:

```bash
# Use platform-appropriate temp dir
# Windows: use $TEMP or /tmp (Git Bash)
# Unix: use /tmp
git clone --depth 1 --branch main https://github.com/bajakota-cyber/claud-app-dev-launchpad.git /tmp/launchpad-sync
```

### Step 4: Compare files

For each file in the upstream `.claude/` folder, compare with the local version:

**Files to sync** (these are launchpad template files):
- `.claude/agents/*.md`
- `.claude/rules/*.md`
- `.claude/skills/*/SKILL.md`
- `.claude/hooks/*.sh`

**Files to MERGE** (not overwrite):
- `.claude/settings.json` - Merge upstream permissions into local. Add new `allow` entries from upstream without removing project-specific ones. Keep local `deny` entries. Merge `hooks` (keep both upstream and local hooks).

**Files to NEVER sync**:
- `CLAUDE.md` - Always project-specific after initial setup
- Any file that exists locally but NOT in the upstream repo (these are project-specific additions)

For each syncable file, run:
```bash
diff --strip-trailing-cr /tmp/launchpad-sync/.claude/agents/architect.md .claude/agents/architect.md
```

Build a list of: new files, modified files, unchanged files.

### Step 5: Apply changes (skip if --dry-run)

**CRITICAL: Never blindly overwrite. Always merge.**

#### For new files (exist upstream, not locally):
- Copy them in as-is. No conflict possible.

#### For modified files (exist in both, content differs):
Do NOT `cp` the upstream file over the local one. Instead, apply a content-aware merge:

1. Read the upstream version and the local version
2. Identify what the upstream version **added or changed** vs the previous version (treat upstream as the "new" and local as the "current base")
3. Apply upstream additions and edits to the local file
4. **Never remove content that exists locally but not upstream** — local additions are project-specific and must be preserved
5. If the same section was changed in both places (true conflict), keep the local version and flag it for the user

In practice, for markdown files this means:
- Lines/sections in upstream but not local → ADD them to local
- Lines/sections in local but not upstream → KEEP them (never delete)
- Same line changed differently → KEEP local, flag as conflict

#### For `settings.json`:
- Merge the `allow` arrays (union of both — never remove local entries)
- Keep local `deny` entries plus any new upstream ones
- Merge `hooks` keeping both upstream and local hooks
- Result must be valid JSON — verify before writing

#### For all files:
- Preserve all project-specific files (anything not in upstream)
- Never delete a local file just because it's not in upstream

### Step 6: Report

Output what happened:

```
## Sync Complete

### Updated Files
- .claude/agents/coach.md (updated: improved scouting prompts)
- .claude/agents/architect.md (updated: better planning steps)

### New Files Added
- .claude/skills/new-skill/SKILL.md

### Unchanged Files
- .claude/rules/security.md
- .claude/skills/checkpoint/SKILL.md

### Preserved (project-specific)
- .claude/agents/my-custom-agent.md (not in upstream, kept as-is)

### Settings Merged
- Added 3 new permission entries from upstream
- Kept 2 project-specific permission entries
```

### Step 7: Cleanup

Remove the temp clone:
```bash
rm -rf /tmp/launchpad-sync
```

## Error Handling

- If `git clone` fails (no network, repo moved): Tell the user "Can't reach the launchpad repo. Check your internet connection or verify the repo URL."
- If a file copy fails: Skip that file, report it, continue with the rest
- If settings.json merge produces invalid JSON: Keep the local version, flag it for the user
