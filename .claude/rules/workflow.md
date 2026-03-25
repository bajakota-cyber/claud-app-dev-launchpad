---
description: Workflow rules for how Claude should approach building things
---

# Workflow Rules

- For new features or significant changes: use the architect agent to PLAN FIRST, then build
- After implementing a feature: use the code-reviewer agent to check for bugs
- After adding API keys, auth, or sensitive features: use the security-scanner agent
- Save important architectural decisions to memory immediately - don't wait
- When the user describes what they want, confirm understanding before building
- Build incrementally: get a basic version working first, then add features
- Test after each significant change - don't build everything and test at the end
- If something isn't working after 2-3 attempts, use the bird-eye agent to check if there's a simpler path
- During long build sessions, periodically use bird-eye to sanity check the approach
- Keep the user informed of what you're doing and why - no black boxes
- Run /sync-launchpad at the start of any new build session to pull the latest launchpad updates
- During long build sessions (2+ hours), run /sync-launchpad again to check for updates
- Use the coach agent periodically to review agent performance, scout for new tools, and keep the launchpad healthy

## Session Startup (do this automatically at the start of every new conversation)
1. Run /sync-launchpad silently to pull latest launchpad updates
2. Read `.claude/engineering-journal.md` — brief the user in 2-3 sentences on where things left off
3. Run `git status` — if uncommitted changes exist, flag them immediately
4. Check if `.claude/.coach-due` exists — if it does, invoke coach immediately before anything else
5. Then ask: "Ready to keep going, or is there something new you want to tackle?"

## Press — Mandatory After Every Significant Work Chunk
After completing any feature, fix, or meaningful block of work — invoke the Press agent.
"Significant" means: a feature was built, a bug was fixed, a file was meaningfully changed.
Do NOT invoke Press for one-line answers, explanations, or clarifying questions.
Press is fast (Haiku, 5 turns) — it will not slow the user down.

### Completion Triggers — When to Fire Press
Fire Press when ANY of these happen:
- User confirms work is done: "ok that worked", "it's working", "nice", "perfect", "looks good", "done", "finished"
- User wants to move on: "next", "let's move on", "what's next", "moving on"
- Code-reviewer just finished its review (Press records the completed work)
- User says "commit" or "push" (Press records BEFORE the commit)
- A feature/fix is clearly complete even if the user hasn't explicitly said so

DO NOT skip Press because you are eager to move to the next task. Record first, then move on.
DO NOT wait for the user to say "run press" — that defeats the purpose of auto-invocation.

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
