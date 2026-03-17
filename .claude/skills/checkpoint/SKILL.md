---
name: checkpoint
description: Saves the current state of the project's architecture, decisions, and progress to memory. Use this before long conversations, before switching topics, or whenever you want to make sure critical context survives conversation compaction.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, TodoWrite
argument-hint: "[optional: specific area to checkpoint]"
---

# Checkpoint - Save Project State to Memory

The user wants to save the current project state so it survives conversation compaction.

## What to Capture

### 1. Project Overview
- What the project is and what it does
- Current tech stack and key dependencies
- Overall architecture (how the pieces fit together)

### 2. What's Been Built So Far
- Run `git log --oneline -20` to see recent work
- Run `git diff --stat` to see uncommitted changes
- List the key files and what they do

### 3. Architectural Decisions
- What patterns are being used and WHY
- State management approach
- API/data flow design
- Any trade-offs that were made and the reasoning

### 4. Current State
- What feature/task is currently in progress?
- What's working and what's not yet working?
- Any known bugs or issues?
- What's the next step?

### 5. Important Context
- Anything the user mentioned that wouldn't be obvious from the code
- User preferences about how to build things
- Constraints or requirements that affect decisions

## How to Save

Write all of the above into a clear, structured memory file. The goal is that if this conversation gets compacted or a NEW conversation starts, reading this memory file should give complete context to continue the work without asking the user to repeat themselves.

Be concise but complete. Focus on the WHY behind decisions, not just the WHAT.

## If $ARGUMENTS specifies an area
Only checkpoint that specific area instead of the whole project. For example:
- `/checkpoint auth` - Save the authentication architecture
- `/checkpoint api` - Save the API design decisions
- `/checkpoint frontend` - Save the frontend architecture
