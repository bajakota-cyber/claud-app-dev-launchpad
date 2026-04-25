---
name: setup-launchpad-local
description: Airgapped first-time setup. Use when you've been given a copy of the launchpad as a folder (zip or shared drive) and want to use it without GitHub. Sets up a local "master" folder that all your projects sync from. No GitHub account or repo needed.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
argument-hint: "[optional: path to where the master folder should live, e.g. C:\\claude-launchpad]"
---

# Setup Launchpad — Local / Airgapped Mode

For sharing the launchpad with someone who shouldn't have GitHub access (or who just wants a simpler setup). This creates a local "master" folder on disk that all their projects sync from. No GitHub. No git. No remote anything.

## When to use this

- You received the launchpad as a zip file or shared folder from someone else
- You want to use the launchpad without setting up GitHub
- You want zero risk of accidentally pushing to someone else's repo
- You're just experimenting and don't want to commit to a GitHub workflow yet

## Process

### Step 1: Determine where the master folder will live

Ask the user where they want the master launchpad folder if not given in `$ARGUMENTS`. Default suggestion: `C:\claude-launchpad\` (Windows) or `~/claude-launchpad/` (Mac/Linux).

**The master folder rules:**
- Should be OUTSIDE any individual project folder
- Should be persistent (don't put it in `/tmp` or Downloads)
- All projects on this machine will sync from this folder

### Step 2: Determine the source of the launchpad files

Ask the user where the launchpad source is right now. Common scenarios:
- They downloaded a zip and extracted it to e.g. `C:\Downloads\claud-app-dev-launchpad-main\`
- A friend shared a folder on a USB drive
- It's already in a folder on their machine

### Step 3: Copy launchpad to the master location

```bash
# Create the master folder
mkdir -p "<MASTER_PATH>"

# Copy the launchpad files into it
cp -r "<SOURCE_PATH>"/. "<MASTER_PATH>/"
```

Verify the master folder now contains:
- `.claude/` (with agents, rules, skills, hooks, settings)
- `CLAUDE.md`
- `.mcp.json`

### Step 4: Set up the launchpad in the current project

If the current project doesn't have `.claude/` yet, copy it in:

```bash
# Copy .claude/ from the master folder
cp -r "<MASTER_PATH>/.claude" ./

# Copy .mcp.json if it doesn't exist
[ ! -f .mcp.json ] && cp "<MASTER_PATH>/.mcp.json" ./
```

### Step 5: Handle CLAUDE.md

If the project has no CLAUDE.md, copy the launchpad one. If it has one already, append the launchpad sections that are missing (Available Agents, Skills, Rules) — same as `/setup-launchpad`.

### Step 6: Write the .launchpad-source config

Tell all the launchpad skills where to pull from / push to:

```bash
echo "<MASTER_PATH>" > .claude/.launchpad-source
```

This is the critical step. Without this file, the skills default to GitHub mode.

### Step 7: Verify

Confirm `.claude/.launchpad-source` was created and contains the master path:

```bash
cat .claude/.launchpad-source
```

### Step 8: Report

```
## Local Launchpad Setup Complete!

### Master folder
- Location: <MASTER_PATH>
- This is your single source of truth — all projects sync from here

### This project
- .claude/ folder copied from master
- .claude/.launchpad-source set to: <MASTER_PATH>
- CLAUDE.md: [created / merged]

### How it works now
- /sync-launchpad → pulls latest from your master folder
- coach → pushes improvements back to your master folder
- master-coach → reviews all projects, updates the master folder
- No GitHub. No git pushes. Fully local.

### For future projects
Run /setup-launchpad-local in any new project and point it to: <MASTER_PATH>

### If you ever want to upgrade to GitHub-based syncing
See INSTALL-ON-GITHUB.md in your master folder for the full guide.
```

## Important Notes

### What "local mode" gives up vs URL mode
- No automatic updates from upstream (Dakota's launchpad) — you only get what's in your master folder
- No collaboration with other people's coaches
- Can't easily share improvements back

### What "local mode" gives you
- Total control — your master folder, your rules
- Zero risk to anyone else's repo
- Works offline
- No GitHub account needed
- Simple file copies, easy to understand

### Updating the master folder later
If someone sends you a new zip:
1. Back up your current master folder (rename it to `claude-launchpad-backup-YYYY-MM-DD`)
2. Extract the new zip to the master folder location
3. Run `/sync-launchpad` in each of your projects to pick up the changes

## Error Handling

- If source path doesn't exist: ask the user to verify the path and try again
- If master folder already exists: ask if they want to overwrite or use a different location
- If `.launchpad-source` write fails: tell the user to create it manually with the master path
