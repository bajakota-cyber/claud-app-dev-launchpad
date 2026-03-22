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
2. Read `.claude/engineering-notebook.md` — brief the user in 2-3 sentences on where things left off
3. Run `git status` — if uncommitted changes exist, flag them immediately
4. Then ask: "Ready to keep going, or is there something new you want to tackle?"

## Git Hygiene (commit often, never lose work)
- When the user says "commit my work", "save my progress", or "push to github": run git add + commit + push
- Suggest committing after every completed feature — don't wait for the user to ask
- Commit message format: short description of what was built/fixed

## Agent Mistake Logging

When the user corrects an agent's **logic, judgment, or a missed check**, append a note to `.claude/agent-feedback.md`:
`- [YYYY-MM-DD] [agent name or "general"] | [project-specific] or [agnostic] | [what went wrong] | [what the correct approach was]`

Tag as **[agnostic]** if the fix would benefit any project using the launchpad.
Tag as **[project-specific]** if it only applies to this codebase or tech stack.

**DO log** (real mistakes):
- Wrong approach that had to be completely reversed
- Missed security issue, bug, or project rule violation
- Architect planned something that got scrapped
- Code reviewer approved something that broke
- Agent used wrong pattern for this project (e.g. wrong terminology, wrong architecture)

**DO NOT log** (cosmetic corrections):
- Layout, position, or spacing changes ("move this field next to that one")
- Label, naming, or wording tweaks ("rename this button")
- Font size, color, or style preferences
- Iterative UI refinements ("make it bigger", "put it on the left")
- User changing their mind about appearance

**Escape hatches** (always override the above):
- User says **"log that"** → always log the previous correction
- User says **"just cosmetic"** → always skip logging
