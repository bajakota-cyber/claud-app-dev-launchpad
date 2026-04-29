---
description: Rules for efficient token usage — get the most out of every message
---

# Token Efficiency Rules

The user pays per token. Wasting tokens on redundant reads, verbose output, or unnecessary exploration is wasting their money. Be efficient without sacrificing quality.

## Don't re-read files
- If you've already read a file in this conversation, don't read it again unless it was modified since
- Before using the Read tool, ask yourself: "Do I already have this file's content in context?"
- If you only need one function from a 500-line file, read just that range (use offset/limit)

## Keep command output lean
- Pipe verbose commands through `head` or `tail` when you only need part of the output
- Use `--quiet` or `--silent` flags when available
- For git log, use `--oneline` and limit with `-n`
- Don't dump entire log files — grep for what you need

## Be specific with searches
- Use Grep with specific patterns, not broad ones that return hundreds of results
- Use Glob with targeted patterns, not `**/*` when you know the directory
- Set `head_limit` on Grep to avoid pulling back massive result sets

## Write concise responses
- Don't repeat back what the user just said
- Don't explain obvious things to this user — they're experienced with the workflow
- Get to the point: what you did, what happened, what's next
- Skip preamble like "Great question!" or "I'd be happy to help!"

## Use subagents for exploration
- When you need to investigate something (search across files, understand a pattern), use a subagent
- The subagent's context is separate — it won't bloat the main conversation
- Only the summary comes back to the main thread

## Compact proactively
- If a conversation is getting long and context-heavy, suggest `/compact` to the user
- After compacting, don't re-read files that are already summarized in the compacted context

## Batch related work
- If you need to read 5 files, read them all in one message (parallel tool calls), not one at a time
- If you need to run independent commands, run them in parallel
- Group related edits to the same file into fewer Edit calls

## Compact discipline (hard rules from real-session diagnostics)
A prior session burned 5 hours of usage in ~3 wall hours running 1,200+ assistant turns with **zero** `/compact` invocations. Cumulative re-tokenization was the #1 cost driver. The rules below carry forward from that diagnostic.

- **Suggest `/compact` to the user every ~30-50 assistant turns** in long sessions. Do not wait until the user notices the session is sluggish.
- **Never let a session pass 100 turns without compacting.** Even mid-task. Compaction at 100 turns is cheaper than the alternative.
- **Cap subagent return verbosity.** When spawning research/audit/dispatch agents, include "Return findings under 250 words" in the spawn prompt. Without that cap, workers return verbose reports that bloat orchestrator context.
- **TodoWrite frugality.** Use TodoWrite for the high-level plan, not every 2-line edit. A previous session burned 59 TodoWrite calls — most were micro-updates. Aim for ≤ 10 calls per session.
- **Re-read audit.** If you have re-read the same file 3+ times in a session, the file likely lives in context already. Verify before reading again. The diagnostic session re-read three TO files 17×, 16×, and 10× respectively — about half of all Read calls were duplicates.
