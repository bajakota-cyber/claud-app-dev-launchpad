---
name: setup-launchpad
description: Sets up the vibe coding launchpad in the current project by pulling agents, rules, skills, and settings from the GitHub repo. Handles merging with existing CLAUDE.md.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
argument-hint: "[optional: --force to overwrite existing .claude/ folder]"
---

# Setup Launchpad

Pull the full vibe coding launchpad into the current project from GitHub.

**Launchpad repo**: https://github.com/bajakota-cyber/claud-app-dev-launchpad

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

### Step 2: Clone the launchpad

```bash
git clone --depth 1 https://github.com/bajakota-cyber/claud-app-dev-launchpad.git /tmp/launchpad-setup
```

If clone fails, tell the user to check their internet connection.

### Step 3: Copy .claude/ and .mcp.json

```bash
# Copy the entire .claude folder
cp -r /tmp/launchpad-setup/.claude ./

# Copy .mcp.json
cp /tmp/launchpad-setup/.mcp.json ./
```

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

### Step 6: Cleanup

```bash
rm -rf /tmp/launchpad-setup
```

### Step 7: Report

```
## Launchpad Setup Complete!

### What was added
- .claude/ folder (6 agents, 4 skills, 3 rules, hooks, settings)
- .mcp.json

### CLAUDE.md
- [Created new / Merged with existing]

### Next steps
- Customize the "Build & Run" section in CLAUDE.md for your project
- You can now use all launchpad skills: /checkpoint, /review, /sync-launchpad
- Claude will automatically follow the launchpad workflow (plan first, review after, etc.)
```

## Error Handling

- If git clone fails: "Can't reach the launchpad repo. Check your internet connection."
- If copy fails: Report which files failed, continue with the rest.
- If CLAUDE.md merge looks wrong: Keep both versions (rename existing to CLAUDE.md.backup) and let the user sort it out.
