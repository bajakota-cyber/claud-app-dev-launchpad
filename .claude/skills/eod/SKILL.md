---
name: eod
description: End-of-day wrap. Chains commit + checkpoint + press + coach in sequence to close out a work session cleanly. Use at the end of a build session.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent, TodoWrite
argument-hint: "[optional: short note about today's session]"
---

# End-of-Day Wrap

The user is closing out a build session. Run a clean, sequential close-out that commits the work, saves architectural state to memory, records what was built in the engineering journal, and runs the coach to push any improvements upstream.

## Why sequential, not parallel

Each step depends on the previous one's output:
- Press reads `git log` to know what to record — so the commit must land first.
- Coach reads `engineering-journal.md` and the shortcomings logs — so Press must finish first.
- Press writing the journal and Coach pushing to the launchpad both touch files; running them in parallel risks conflicts.

Do NOT spawn these as parallel subagents. Run them one at a time, in order.

## Process

### Step 1 — Commit any uncommitted work

1. Run `git status` to see what's outstanding.
2. If there are uncommitted changes:
   - Stage only the files that belong in this commit (avoid `git add -A` if there are .env / secrets / build artifacts loose).
   - Draft a short commit message that reflects what changed today. Follow the repo's existing message style (run `git log --oneline -5` if unsure).
   - Commit and push.
3. If the tree is clean, skip to Step 2 and note "nothing to commit" in the final summary.

If `$ARGUMENTS` contains a session note, include it as the first line of the commit message (or as the commit body if multiple changes are being grouped).

### Step 2 — Checkpoint architectural state

Invoke the `/checkpoint` skill (or run its equivalent inline) to save the current architectural state to memory. This is what survives conversation compaction and lets tomorrow's session pick up cleanly.

### Step 3 — Run the Press agent

Invoke the `press` agent to record what was built today in `.claude/engineering-journal.md` and to log any shortcomings to `.claude/project-shortcomings.md` or `.claude/launchpad-shortcomings.md`.

**Verify after Press finishes:** Press must have actually modified `engineering-journal.md`. If the file timestamp hasn't moved or no new entry exists, Press failed silently — write the journal entry yourself before continuing. Per workflow.md, never silently skip a failed subagent's job.

### Step 4 — Run the Coach agent

Invoke the `coach` agent. Coach will:
- Pull the latest launchpad from the configured source
- Review the shortcomings logs Press just updated
- Make targeted improvements to agents/rules/skills
- Push launchpad-level fixes upstream so all projects benefit

If `.claude/.coach-due` exists, delete it after coach finishes.

### Step 5 — Final summary

Give the user a short close-out (under 200 words):
- What was committed (commit SHA + one-line summary)
- What the checkpoint captured
- What Press logged
- What Coach pushed upstream (if anything)
- Anything still open or flagged for tomorrow

## Failure handling

If any step fails, STOP and tell the user. Do not continue to the next step pretending the failed step worked — the chain breaks if Press never wrote the journal or if Coach never synced.

## Notes

- This skill is meant for the END of a working session. Don't use it mid-session — for that use `/checkpoint` and Press individually.
- If the user runs `/eod` and the tree has zero changes AND no recent work to journal, tell them so and ask whether they still want a coach run.
