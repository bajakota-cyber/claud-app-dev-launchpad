---
description: Workflow rules for how Claude should approach building things
---

# Workflow Rules — MANDATORY, NOT OPTIONAL

These rules are NOT suggestions. They are requirements. Skipping them because you're "in the zone" or "under time pressure" is exactly when they matter most. Past sessions have failed specifically because these rules were ignored.

## Agent Triggers — MUST follow, no exceptions

| Trigger | Agent | When |
|---------|-------|------|
| New feature or significant change | **architect** | BEFORE writing any code -- UNLESS the user has already provided detailed specs or step-by-step instructions (they did the planning). When in doubt, ask "Should I plan this first or just start building?" |
| Feature implemented | **code-reviewer** | IMMEDIATELY after. Every feature. Every time. No skipping. |
| API keys, auth, tokens, secrets, webhooks added | **security-scanner** | After EACH addition, not once at the end. |
| Code that spends money, manages ads/billing, or creates financial transactions | **security-scanner** | IMMEDIATELY. Money code = security-critical code. |
| 2 failed fix attempts on the same issue, OR current approach requires workarounds/hacks/fighting the platform | **bird-eye** | Stop. Do not attempt fix #3. Also invoke when the solution feels like it is fighting the framework or platform rather than working with it. |
| Feature/fix completed | **press** | Record BEFORE moving to next task. |
| Session end or `.claude/.coach-due` exists | **coach** | Invoke immediately. |

**Self-check (MANDATORY — run this mental checklist after EVERY Write/Edit cycle):**
1. Have I created or modified 3+ files since the last code-reviewer run? **STOP and run code-reviewer NOW.** This includes batch building sessions where multiple services/handlers are created in rapid succession — do not wait until "the feature is done." Review in batches.
2. Have I added any secret, token, key, or API credential? **STOP and run security-scanner NOW.**
3. Have I added any code that can spend money, create financial transactions, modify billing, manage ad budgets, or access payment APIs? **STOP and run security-scanner NOW.** Money code is as sensitive as credential code.
4. Have I completed a feature or fix without invoking Press? **STOP and run Press NOW.**

**If you catch yourself about to skip any of these because "it's a small change" or "I'll do it after the next one" — that is exactly when bugs and security gaps ship. Do it now.**

## Session Startup — Runs ONCE when a new conversation begins

This fires ONE TIME at the start of a new conversation (app restart, new session, opening a new project). It does NOT repeat mid-session. The user keeps long-running sessions, so this is rare.

When it fires, run it BEFORE any user request:

1. Run /sync-launchpad silently to pull latest launchpad updates
2. Read `.claude/engineering-journal.md` — brief the user in 2-3 sentences on where things left off
3. Run `git status` — if uncommitted changes exist, flag them immediately
4. Check if `.claude/.coach-due` exists — if it does, invoke coach immediately before anything else
5. Then ask: "Ready to keep going, or is there something new you want to tackle?"

**Mid-session coverage** (these are handled by separate rules, NOT by re-running the startup checklist):
- Launchpad sync: covered by the "2+ hours" rule below
- Coach-due: covered by the coach-due rule — check whenever the file appears
- Agent enforcement: covered by the trigger table above

## Subagent Failures — NEVER silently skip

When you invoke a subagent (Press, Coach, code-reviewer, security-scanner, etc.), you are responsible for verifying it actually did its job. Subagents can fail silently — they return without error but don't actually write files or produce useful output.

**After every subagent returns:**
1. Check: Did it produce the expected output? (e.g., Press should have written to engineering-journal.md, code-reviewer should have reported findings)
2. If it failed or produced nothing useful: **do the task yourself directly.** Don't move on. Don't log "agent failed" and skip it.
3. If you can't figure out why it failed: **tell the user.** Say what agent failed, what it was supposed to do, and that you're doing it manually.

**NEVER:**
- Assume "permissions" are the problem without checking settings.json
- Blame the subagent and move on without completing the task
- Silently skip a failed agent's job
- Say "the agent ran" when it produced no results

**The rule is simple: the task matters, not who does it. If the subagent can't do it, you do it.**

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

**Press Self-Check (same weight as code-reviewer self-check):**
If you have completed 2+ features/fixes without invoking Press, STOP what you are doing and invoke Press NOW. Do not batch Press at the end of a session — shortcomings lose context when recorded hours after they happen. Press should fire after EACH significant chunk, not once at session end.

## Coach — Run Immediately If Due
If `.claude/.coach-due` exists at ANY point (session start, mid-session, the Stop hook will signal it):
- Invoke coach immediately
- After coach finishes, delete `.claude/.coach-due`

## Windows Process Management (this project runs on Windows)

When you need to kill node processes on Windows from Claude's bash shell:
- **DO use:** `powershell.exe -Command "Get-Process node* | Stop-Process -Force"`
- **DO NOT use:** `kill`, `taskkill`, or `cmd.exe /c taskkill` — these fail or behave inconsistently from Claude's bash shell on Windows.
- **For port-specific kills:** `powershell.exe -Command "Get-NetTCPConnection -LocalPort PORT -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }"`
- **Prevent duplicate bot instances:** Use a TCP port lock (e.g., port 4599) so only one instance can run. This is more reliable than lockfiles on Windows.

## Long Session Hygiene
- If a conversation is getting long and sluggish, suggest `/compact` to the user
- During long sessions (2+ hours), run `/sync-launchpad` to check for updates from other coaches
- Suggest committing work periodically — don't let hours of work sit uncommitted

## Git Hygiene (commit often, never lose work)
- When the user says "commit my work", "save my progress", or "push to github": run git add + commit + push
- Suggest committing after every completed feature — don't wait for the user to ask
- Commit message format: short description of what was built/fixed
- **BEFORE every push to the launchpad repo:** ALWAYS run `git pull origin main --rebase` first and READ the incoming changes. Other project coaches push updates frequently — blindly pushing without pulling first risks overwriting their work. Never assume your local copy is up to date.

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
