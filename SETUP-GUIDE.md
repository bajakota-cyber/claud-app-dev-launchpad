# Vibe Coding Launchpad - Setup Guide

## What Is This?
A pre-configured Claude Code setup that makes building apps faster, safer, and less frustrating. Instead of just chatting back and forth, Claude now has specialized agents, automated security checks, and a memory system that survives long conversations.

## How To Use It

### Starting a New Project
1. Copy this entire folder (or its contents) to wherever you want your new project
2. Open Claude Code in that folder
3. Type: `/new-project my-app-name A description of what I want to build`
4. Claude will plan the architecture, scaffold the project, and set everything up

### During Development
Just describe what you want. Claude will automatically:
- **Plan first** using the Architect agent (no more jumping straight into code that needs to be rewritten)
- **Check for security issues** after writing code (catches exposed API keys in real-time)
- **Save critical context** before conversation compaction (no more losing your place)

### Useful Commands
- `/checkpoint` - Save your project state to memory (do this before long breaks or when switching topics)
- `/review` - Run a full code review + security scan on recent changes
- `/new-project` - Scaffold a new project from scratch

### When Conversations Get Long
Claude's memory system has three layers:
1. **Auto-save on compaction** - A hook automatically snapshots your project state before conversations compress
2. **Manual checkpoints** - Use `/checkpoint` to explicitly save important context
3. **Architectural memory** - The Architect agent saves design decisions that persist across conversations

## What's Inside

```
.claude/
  agents/
    architect.md        - Plans before coding (uses Opus for quality)
    bird-eye.md         - Zooms out to catch rabbit holes and find simpler paths (Opus)
    code-reviewer.md    - Catches bugs + code hygiene (DRY, dead code, refactoring)
    security-scanner.md - Finds security vulnerabilities
    test-writer.md      - Writes and runs tests for your code
  skills/
    new-project/        - Project scaffolding (/new-project)
    checkpoint/         - Save state to memory (/checkpoint)
    review/             - Code review + security scan (/review)
  hooks/
    security-check.sh   - Auto-checks edited files for secrets
    pre-compact-save.sh - Auto-saves state before compaction
  rules/
    security.md         - Security coding standards
    code-quality.md     - Code quality standards
    workflow.md         - How Claude should approach building
  settings.json         - Permissions and hook configuration
.mcp.json               - MCP server config (add per-project)
CLAUDE.md               - Main project instructions
.gitignore              - Sensible defaults
```

## Adding MCP Servers (Optional, Per-Project)
MCP servers connect Claude to external tools. Add them when your project needs them:

```bash
# GitHub (for PR reviews, issue management)
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/

# Database (if your project uses PostgreSQL)
claude mcp add --scope project --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://localhost:5432/mydb"
```

## Tips
- **Don't skip the planning step.** It feels slower but saves massive debugging time.
- **Use /checkpoint liberally.** It's cheap insurance against losing context.
- **Trust the security scanner.** If it flags something, fix it before moving on.
- **Keep CLAUDE.md updated.** When your project's build commands or structure change, update CLAUDE.md so Claude doesn't get confused.

## What About Token Usage?
This setup helps with token efficiency in several ways:
- **Sub-agents run in separate contexts** - A security scan doesn't eat into your main conversation's context
- **Rules load by file path** - Security rules only load when you're editing code files, not when discussing architecture
- **Pre-compaction snapshots** - Instead of Claude having to re-read everything after compaction, it reads a concise snapshot
- **Focused agents use Sonnet** - Only the Architect uses Opus (for quality planning). Everything else uses the faster, cheaper Sonnet model.
