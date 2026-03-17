---
name: review
description: Runs a comprehensive code review on recent changes using the code-reviewer and security-scanner agents. Use after implementing a feature or before committing.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Agent, TodoWrite
argument-hint: "[optional: specific file or area to review]"
---

# Code Review

Run a thorough review of recent changes.

## Process

1. **Check what changed**: Run `git diff` and `git status` to understand the scope

2. **Run Code Reviewer agent**: Delegate to the `code-reviewer` agent to check for bugs and quality issues

3. **Run Security Scanner agent**: Delegate to the `security-scanner` agent to check for security problems

4. **Summarize findings**: Give the user a clear summary:
   - CRITICAL issues that must be fixed
   - Warnings that should be fixed
   - Suggestions that would be nice to fix
   - Overall assessment: safe to commit or needs work?

## If $ARGUMENTS specifies a target
Only review the specified file or area instead of all changes.

## Important
- Run both agents. Security issues are just as important as bugs.
- Be honest. If there are no issues, say so. Don't invent problems.
- Present findings in order of severity so the user knows what to fix first.
