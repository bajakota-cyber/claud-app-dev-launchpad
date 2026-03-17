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
