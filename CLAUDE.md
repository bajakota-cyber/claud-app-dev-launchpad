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

## Available Skills
- `/new-project [name]` - Scaffold a new app project
- `/checkpoint` - Save current architectural state to memory
- `/review` - Run a code review on recent changes

## Important Rules
- ALWAYS use the architect agent before building a new feature or making big changes
- ALWAYS run security-scanner after adding environment variables, API integrations, or auth
- Use bird-eye when debugging gets frustrating, when a feature feels overly complex, or periodically during long sessions
- Save architectural decisions to memory so they survive conversation compaction
- When in doubt, plan first, build second

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
