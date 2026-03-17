---
name: new-project
description: Scaffolds a new app project with proper structure, dependencies, and configuration. Use at the start of any new project.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TodoWrite
argument-hint: "[project-name] [description of what to build]"
---

# New Project Scaffolding

The user wants to start a new project. Your job is to set it up RIGHT from the beginning so the rest of the build goes smoothly.

## Step 1: Understand What They Want
Parse $ARGUMENTS for the project name and description. If they didn't provide enough info, ask:
- What kind of app? (web app, API, CLI tool, mobile, etc.)
- What framework preference? (or should you pick one?)
- Any specific features they already know they want?

## Step 2: Use the Architect Agent
ALWAYS delegate to the architect agent first to plan the project structure. This is non-negotiable - planning saves hours of debugging later.

The architect should decide:
- Tech stack (framework, language, key dependencies)
- Folder structure
- Core architecture (how data flows, state management, routing)

## Step 3: Scaffold the Project
Based on the architect's plan:

1. Initialize the project (npm init, create-react-app, vite, etc.)
2. Install dependencies
3. Set up the folder structure
4. Create essential config files:
   - `.gitignore` (MUST include `.env`, `node_modules`, build output)
   - `.env.example` (template for environment variables - NEVER put real secrets here)
   - Basic README with setup instructions

5. Update the project's `CLAUDE.md` with:
   - Project description and purpose
   - Build, run, and test commands
   - Key architectural decisions (from the architect)
   - File structure overview

6. Set up `.claude/launch.json` for the dev server so Claude Preview works

## Step 4: Save to Memory
Save the following to auto-memory:
- Project purpose and what it does
- Tech stack choices and WHY they were chosen
- Core architecture decisions
- File structure rationale

## Step 5: Run the Security Scanner
Run the security-scanner agent on the fresh project to establish a clean baseline.

## Step 6: Initial Commit
Create the initial git commit with all the scaffolded files.

## Important
- Keep it SIMPLE. Don't over-scaffold. Start with the minimum and let the user add complexity as needed.
- Use the MOST POPULAR, WELL-MAINTAINED tools for the job. No obscure frameworks.
- Every dependency must earn its place. Don't add a library for something you can do in 5 lines of code.
