---
name: setup-launchpad
description: Sets up the vibe coding launchpad in the current project by pulling agents, rules, skills, and settings from the GitHub repo. Handles merging with existing CLAUDE.md.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
argument-hint: "[optional: --force to overwrite existing .claude/ folder]"
---

# Setup Launchpad

Pull the full vibe coding launchpad into the current project. Source can be GitHub URL or a local folder.

**Default source (GitHub)**: https://github.com/bajakota-cyber/claud-app-dev-launchpad

For airgapped / shared / local-only setup, see `/setup-launchpad-local`.

## Process

### Step 1: Check current state

Check what already exists in the current project:

```bash
ls -la .claude/ 2>/dev/null
ls -la CLAUDE.md 2>/dev/null
ls -la .mcp.json 2>/dev/null
```

- If `.claude/` already exists and `--force` was NOT passed, warn the user: "This project already has a .claude/ folder. Run `/setup-launchpad --force` to overwrite, or use `/sync-launchpad` to update."
- If `--force` was passed, continue and overwrite.

### Step 2: Determine the launchpad source

Check `$ARGUMENTS` for a path or URL. If none given:
- Default to GitHub URL: `https://github.com/bajakota-cyber/claud-app-dev-launchpad.git`

If `$ARGUMENTS` looks like a local path (starts with `/`, `C:`, `D:`, `~`), use LOCAL mode.
If it looks like a URL, use URL mode.

### Step 3: Fetch the launchpad

**URL mode:**
```bash
git clone --depth 1 <URL> /tmp/launchpad-setup
```

**LOCAL mode:**
```bash
cp -r "<LOCAL_PATH>" /tmp/launchpad-setup
```

If fetch fails, tell the user to check the source location.

### Step 4: Copy .claude/ and .mcp.json

```bash
# Copy the entire .claude folder
cp -r /tmp/launchpad-setup/.claude ./

# Copy .mcp.json
cp /tmp/launchpad-setup/.mcp.json ./
```

### Step 4b: Write the .launchpad-source config

Record the source so future syncs know where to pull from:

```bash
echo "<URL_OR_LOCAL_PATH>" > .claude/.launchpad-source
```

This file tells `/sync-launchpad`, `/coach`, and `/master-coach` where to pull from and push to. Without it, they fall back to the default GitHub URL.

### Step 4: Handle CLAUDE.md (the tricky part)

**If NO existing CLAUDE.md**: Just copy it in.
```bash
cp /tmp/launchpad-setup/CLAUDE.md ./
```
Then tell the user to customize the "Build & Run" section for their project.

**If CLAUDE.md ALREADY EXISTS**: Merge them.
1. Read the existing CLAUDE.md
2. Read the launchpad CLAUDE.md
3. Append the launchpad sections that are missing from the existing file:
   - "Available Agents" section (if not present)
   - "Available Skills" section (if not present)
   - "Important Rules" section (if not present)
   - "Auto-Sync" section (if not present)
4. Do NOT overwrite project-specific content (project description, build commands, etc.)
5. Add a comment at the top of the merged sections: `<!-- Launchpad sections below - managed by /sync-launchpad -->`

### Step 5: Ensure .gitignore has necessary entries

Check if `.gitignore` exists. If it does, make sure it includes:
- `.env`
- `node_modules/`

If `.gitignore` doesn't exist, copy the one from the launchpad repo.

### Step 5b: Verify git commit identity (privacy — see rules/git-identity.md)

A personal email in `git config user.email` gets baked into every commit and pushed to
GitHub. Check it now, before any commit is made:

```bash
git config user.email
git config user.name
```

- If the email is a **real inbox** (`@gmail.com`, `@company.com`, an ISP/work address) — or
  is empty — STOP and tell the user: their commits would expose that address publicly. Have
  them set their GitHub **no-reply** instead (found at GitHub → Settings → Emails → "Keep my
  email addresses private", shape `<ID>+<username>@users.noreply.github.com`):

  ```bash
  git config user.name  "your-handle"
  git config user.email "<ID>+<username>@users.noreply.github.com"
  ```

  Do NOT hardcode a specific address here — it's per-account, and it's the user's to choose.
- If it's already a `*@users.noreply.github.com`, it's fine — continue.
- Also remind them (once per GitHub account) to enable **both** email guards at Settings →
  Emails: "Keep my email addresses private" and "Block command line pushes that expose my
  email." See `.claude/rules/git-identity.md` for the full policy.

### Step 6: Cleanup

```bash
rm -rf /tmp/launchpad-setup
```

### Step 7: Report

```
## Launchpad Setup Complete!

### What was added
- .claude/ folder (agents, skills, rules incl. git-identity, hooks, settings)
- .mcp.json
- .claude/.launchpad-source (points to: <URL or local path>)

### CLAUDE.md
- [Created new / Merged with existing]

### Next steps
- Customize the "Build & Run" section in CLAUDE.md for your project
- You can now use all launchpad skills: /checkpoint, /review, /sync-launchpad
- Claude will automatically follow the launchpad workflow (plan first, review after, etc.)
```

## Error Handling

- If git clone fails: "Can't reach the launchpad repo. Check your internet connection or verify the URL."
- If local copy fails: "Launchpad master folder not found at <path>. Check the path is correct."
- If copy fails: Report which files failed, continue with the rest.
- If CLAUDE.md merge looks wrong: Keep both versions (rename existing to CLAUDE.md.backup) and let the user sort it out.
