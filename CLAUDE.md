# Vibe Coding Launchpad

## How This Project Works
This is a **template launchpad** for vibe-coding apps with Claude Code. Copy `.claude/`, `.mcp.json`, and `CLAUDE.md` into any new project to get the full setup.

## Workflow (How You Should Build Apps)
1. **Start with /new-project** to scaffold your app
2. **Describe what you want** - Claude will use the Architect agent to plan before coding
3. **Claude builds it** using sub-agents for review, testing, and security
4. **Use /checkpoint** before long conversations to save your progress
5. **Use /review** when you want a quality check

## Available Agents
- **architect**: Plans features before coding. Saves decisions to memory so you never lose context.
- **bird-eye**: Zooms out and asks "are we even solving this the right way?" Catches rabbit holes and finds simpler paths.
- **code-reviewer**: Reviews code for bugs AND code hygiene (DRY violations, dead code, refactoring needs).
- **security-scanner**: Checks code for exposed secrets, API keys, and common vulnerabilities.
- **test-writer**: Writes and runs tests for your code to catch bugs before shipping.
- **coach**: Reviews agent performance, scouts for new tools, and keeps the launchpad up to date. Pushes improvements to the GitHub repo so all projects benefit.

## Available Skills
- `/new-project [name]` - Scaffold a new app project
- `/checkpoint` - Save current architectural state to memory
- `/review` - Run a code review on recent changes
- `/sync-launchpad` - Pull latest agents, rules, and skills from the launchpad repo
- `/sync-launchpad --dry-run` - Preview what would change without applying
- `/setup-launchpad` - First-time setup: pull the full launchpad into a new or existing project

## Important Rules
- ALWAYS use the architect agent before building a new feature or making big changes
- ALWAYS run security-scanner after adding environment variables, API integrations, or auth
- Use bird-eye when debugging gets frustrating, when a feature feels overly complex, or periodically during long sessions
- Save architectural decisions to memory so they survive conversation compaction
- When in doubt, plan first, build second
- Periodically use the coach agent to review agent performance and scout for new tools
- Run `/sync-launchpad` at the start of new sessions to check for launchpad updates

## Auto-Sync
At the start of each build session, run `/sync-launchpad --dry-run` to check for launchpad updates.
During sessions longer than 2 hours, check again. This keeps all your projects on the latest agents and tools.

## Build & Run
Update these per-project:
- Build: `npm run build` (or whatever your project uses)
- Dev: `npm run dev`
- Test: `npm test`

## Adding MCP Servers
When your project needs external tools (GitHub, database, etc.), add them to `.mcp.json`:
```bash
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/
```
