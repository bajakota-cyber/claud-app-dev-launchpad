---
description: Workflow rules for how Claude should approach building things
---

# Workflow Rules — MANDATORY, NOT OPTIONAL

These rules are NOT suggestions. They are requirements. Skipping them because you're "in the zone" or "under time pressure" is exactly when they matter most. Past sessions have failed specifically because these rules were ignored.

## Agent Triggers — MUST follow, no exceptions

| Trigger | Agent | When |
|---------|-------|------|
| New feature or significant change | **architect** | BEFORE writing any code. Not after. Not during. Before. |
| Feature implemented | **code-reviewer** | IMMEDIATELY after. Every feature. Every time. No skipping. |
| API keys, auth, tokens, secrets, webhooks added | **security-scanner** | After EACH addition, not once at the end. |
| 2 failed fix attempts on the same issue | **bird-eye** | Stop. Do not attempt fix #3. Invoke bird-eye. |
| Feature/fix completed | **press** | Record BEFORE moving to next task. |
| Session end or `.claude/.coach-due` exists | **coach** | Invoke immediately. |

**Self-check:** If you've built 3+ files without running code-reviewer, STOP and run it now. If you've added any secret/token/key without running security-scanner, STOP and run it now.

## Session Startup — MANDATORY, NEVER SKIP

This runs BEFORE any user request. Not after. Not "when convenient." Before.

Even if the user immediately asks for something urgent — run the checklist first. It takes 30 seconds. Skipping it has caused entire sessions to fail.

1. Run /sync-launchpad silently to pull latest launchpad updates
2. Read `.claude/engineering-journal.md` — brief the user in 2-3 sentences on where things left off
3. Run `git status` — if uncommitted changes exist, flag them immediately
4. Check if `.claude/.coach-due` exists — if it does, invoke coach immediately before anything else
5. Then ask: "Ready to keep going, or is there something new you want to tackle?"

## General Rules
- Save important architectural decisions to memory immediately - don't wait
- When the user describes what they want, confirm understanding before building
- Build incrementally: get a basic version working first, then add features
- Test after each significant change - don't build everything and test at the end
- During long build sessions, periodically use bird-eye to sanity check the approach
- Keep the user informed of what you're doing and why - no black boxes
- Run /sync-launchpad at the start of any new build session to pull the latest launchpad updates
- During long build sessions (2+ hours), run /sync-launchpad again to check for updates
- Use the coach agent periodically to review agent performance, scout for new tools, and keep the launchpad healthy

## Press — MANDATORY After Every Significant Work Chunk

After completing any feature, fix, or meaningful block of work — invoke the Press agent.
"Significant" means: a feature was built, a bug was fixed, a file was meaningfully changed.
Do NOT invoke Press for one-line answers, explanations, or clarifying questions.
Press is fast — it will not slow the user down.

**CRITICAL: When invoking Press as a subagent, you MUST use the Write and Edit tools to actually write to the log files. "Researching what to write" and then not writing is a failure. If Press finishes without modifying engineering-journal.md, it failed — write the entry yourself.**

### Completion Triggers — When to Fire Press
Fire Press when ANY of these happen:
- User confirms work is done: "ok that worked", "it's working", "nice", "perfect", "looks good", "done", "finished"
- User wants to move on: "next", "let's move on", "what's next", "moving on"
- Code-reviewer just finished its review (Press records the completed work)
- User says "commit" or "push" (Press records BEFORE the commit)
- A feature/fix is clearly complete even if the user hasn't explicitly said so

DO NOT skip Press because you are eager to move to the next task. Record first, then move on.
DO NOT wait for the user to say "run press" — that defeats the purpose of auto-invocation.

**Fallback:** If Press subagent fails to write files for any reason, YOU write the journal entry directly. No excuses. The log must be updated.

## Coach — Run Immediately If Due
If `.claude/.coach-due` exists at ANY point (session start, mid-session, the Stop hook will signal it):
- Invoke coach immediately
- After coach finishes, delete `.claude/.coach-due`

## Git Hygiene (commit often, never lose work)
- When the user says "commit my work", "save my progress", or "push to github": run git add + commit + push
- Suggest committing after every completed feature — don't wait for the user to ask
- Commit message format: short description of what was built/fixed

## Agent Mistake Logging

When the user corrects an agent's **logic, judgment, or a missed check**, log it to the right file:

- **Applies only to this project** (wrong terminology, project-specific rule violated, this tech stack only) → append to `.claude/project-shortcomings.md`
- **Any project would hit this** (agent missed something it should always catch, workflow gap, missing skill) → append to `.claude/launchpad-shortcomings.md`

Format for both files:
```
## [YYYY-MM-DD] — [title]
**Issue:** What went wrong and which agent was involved
**Impact:** What it cost (wrong code written, had to redo work, etc.)
**Suggestion:** What should change to prevent it
**Status:** open
---
```

**DO log** (real mistakes):
- Wrong approach that had to be completely reversed
- Missed security issue, bug, or project rule violation
- Architect planned something that got scrapped
- Code reviewer approved something that broke
- Agent used wrong pattern for this project

**DO NOT log** (cosmetic corrections):
- Layout, position, or spacing changes
- Label, naming, or wording tweaks
- Font size, color, or style preferences
- User changing their mind about appearance

**Escape hatches:**
- User says **"log that"** → always log the previous correction
- User says **"just cosmetic"** → always skip logging
