---
name: setup
description: Friendly onboarding for the Vibe Coding Launchpad. Run it first on a launchpad you just downloaded or were given. It swaps the original author's personal settings (name, GitHub account, commit identity) for yours, explains what the launchpad is, how to use it and what each agent does, then (optionally) links it to your OWN GitHub repo or a local master folder so it's fully yours. Use when someone is new to the launchpad, just downloaded or received a copy, asks "what is this / how do I use this", or wants to make the launchpad their own.
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
argument-hint: "[optional: nothing needed — just run /setup]"
---

# Welcome to the Vibe Coding Launchpad 🚀

This skill is a **guided tour**. Someone shared this launchpad with you, or you downloaded it, and you want to know what it is and how to make it yours. Walk the user through it conversationally, in plain language. They may be a non-developer "vibe coder", so never assume technical knowledge and never dump jargon.

**Golden rules for running this skill:**
- Go ONE phase at a time. After each phase, pause and let the user react before moving on. Do not wall-of-text the whole thing at once.
- Keep it warm and encouraging. This is an intro, not a manual.
- NEVER push to git, create a repo, or change remotes without the user explicitly saying yes in Phase 4.
- This launchpad was originally built by **Dakota** (GitHub account **`bajakota-cyber`**, repo `bajakota-cyber/claud-app-dev-launchpad`). A straight download still carries some of his personal settings. Phase 0 swaps those for the user's own. The user is NOT Dakota: never commit as him, never push to his account, never write reports addressed to him.

---

## Phase 0: Make sure it's yours

Check whether this copy still carries the original author's personal settings:

```bash
grep -rn -i -E "dakota|bajakota" .claude/ CLAUDE.md --exclude-dir=setup 2>/dev/null   # skips this skill's own folder
git remote get-url origin 2>/dev/null     # only if this folder is a git repo
cat .claude/.launchpad-source 2>/dev/null # where updates come from, if set
```

- **No hits** → it's already been made personal. Say so in one line and go to Phase 1.
- **Hits** → explain in plain words, roughly:

> "This launchpad was built by Dakota, and a few files still have his personal settings: his name, his GitHub account as the place improvements get saved, and the name your commits would be signed with. I'd like to swap those for yours, so your Claude never tries to act as him or save changes to his account. It only changes these setup files on your computer. Okay?"

Wait for a yes. Then ask what name they'd like Claude to use for them. Then make these changes, and ONLY these:

1. **Commit identity.** In `.claude/agents/coach.md` and `.claude/skills/master-coach/SKILL.md`, remove the hardcoded `git config user.email "...bajakota..."` / `git config user.name "Dakota"` lines. Replace them with: *use the user's own git identity (see `.claude/rules/git-identity.md`); if none is set, ask the user.*
2. **Push credentials.** In `.claude/agents/coach.md`, replace the whole "Push using the bajakota-cyber PAT" step (the `BAJAKOTA_GH_TOKEN` block) with: *push with the user's normal git login, and only to a source the user owns (see rule 3).*
3. **Where improvements go.** The skills fall back to Dakota's public repo URL when `.claude/.launchpad-source` is missing. Leave that URL as a **read-only** place to pull improvements from, but add this rule next to the coach's push step: *Only push if `.claude/.launchpad-source` exists and points to the user's OWN repo or local folder. Never push to `bajakota-cyber/claud-app-dev-launchpad` or any default URL. If no source of the user's own is linked yet, skip the push and say so.* (Phase 4 links their own source.)
4. **The person.** Where a file talks about Dakota as *the person being helped* (for example "Output a clear report for Dakota", "Flagged for Dakota", "Dakota needs to see", "all of Dakota's projects", "(default for Dakota's setup)", "upstream (Dakota's launchpad)": that last one can say "the original author's launchpad"), replace "Dakota" with the user's name.

**Leave alone:** lessons-learned examples that mention past projects (e.g. "Past failure: ODRP …"). They're useful examples, not settings. Don't touch anything else either.

Afterwards, re-run the grep to confirm only the read-only URL and harmless examples remain. Then tell the user in 2–3 plain lines what changed.

---

## Phase 1: What is this thing?

Explain, in your own warm words, roughly this:

> The Vibe Coding Launchpad is a starter kit that makes Claude Code a better app-building partner. Instead of just chatting, Claude gets a small "team" of specialized helpers (agents), automatic safety checks, and a memory system that survives long conversations. You drop it into any project folder and Claude automatically plans before coding, reviews its own work, checks for security problems, and keeps notes so it doesn't lose the plot on long sessions.

Then tell them what they actually have in front of them:
- A `.claude/` folder (the agents, skills, rules, hooks, and settings)
- A `.mcp.json` (pre-wired tools, like live library docs)
- A `CLAUDE.md` (the instructions Claude reads for every project)

Ask: **"Want me to walk you through what each part does?"** Wait for them.

---

## Phase 2: Meet the team (the agents)

Explain each agent in one friendly line. These live in `.claude/agents/`. (Read the folder first to make sure this list matches what's actually installed. Agents may have been added or removed.)

- **architect**: Plans before any code gets written. Thinks through the approach, researches your project, and makes a task list so you don't build the wrong thing twice.
- **bird-eye**: The "are we doing this the hard way?" agent. Zooms out when things get messy and catches rabbit holes before they eat your afternoon.
- **code-reviewer**: Reads new code for real bugs AND tidies up (dead code, copy-paste, messy naming) so the project doesn't rot.
- **security-scanner**: Hunts for exposed passwords/API keys, risky patterns, and (if your app can spend money) missing spending safeguards.
- **test-writer**: Writes practical tests that catch real breakage, not busywork tests.
- **press**: The quiet note-taker. After each chunk of work it logs what was built and what could be better, so nothing gets forgotten.
- **coach**: The team's manager. Reviews how the other agents are doing, scouts new tools, and improves the launchpad over time.

Then mention the **skills** (the `/slash` commands) at a high level. (Read `.claude/skills/` first and match what's installed.)
- `/new-project`: scaffold a brand-new app
- `/checkpoint`: save your project's state to memory before a break
- `/review`: run a code + security review on recent work
- `/hygiene`: deep-clean the codebase (dead code, duplication)
- `/eod`: "end of day" wrap-up (commit + checkpoint + notes)
- `/setup-launchpad`: copy the launchpad into another project folder
- `/sync-launchpad`: pull the latest launchpad improvements (once you've linked a source; see Phase 4)
- `/setup`: this tour. Re-run it anytime.

Ask: **"Want to see how you'd actually use this day to day?"** Wait.

---

## Phase 3: How you actually use it

Keep this concrete and short:

1. **Starting something new?** Just say what you want to build, or run `/new-project my-app a description of what I want`. The architect plans it, then Claude builds it.
2. **Building day to day?** Just talk normally. The agents fire automatically: planning before big changes, reviewing after, flagging security stuff. You don't have to summon them.
3. **About to take a break or switch topics?** Run `/checkpoint` so Claude remembers where things stood.
4. **Want a quality pass?** Run `/review`.

Reassure them: *"You don't have to memorize any of this. The agents mostly run on their own. The main thing is: describe what you want, and let Claude plan before it builds."*

Then ask the key question that leads into Phase 4:

> **"Do you like this setup and want to make it your own, so you can save it, reuse it across projects, and keep your own improvements? I can help you link it to your own GitHub, or just keep it as simple local files. Totally optional."**

- If they say no / not now → wrap up warmly (see "Wrapping up"). Do nothing to git.
- If they want it local-only → go to **Phase 4 (Local)**.
- If they want GitHub → go to **Phase 4 (GitHub)**.

---

## Phase 4 (GitHub): Make it yours on GitHub

Goal: link THIS launchpad to the USER'S OWN new GitHub repo. Never push to the original author's repo or anyone else's.

**First, a plain-language explainer:**
> We'll create a private repository (a "repo") on your own GitHub account. Think of it as your personal cloud folder for the launchpad. Then we connect this folder to it. After that, your coach can save improvements to it, and any project can pull the latest with `/sync-launchpad`.

**Check what they have:**
```bash
git --version        # is git installed?
gh --version         # is the GitHub CLI installed? (optional but easiest)
gh auth status       # are they logged into GitHub CLI?
git remote get-url origin 2>/dev/null   # is this folder already linked somewhere?
```

**If `origin` already points at someone else's repo** (e.g. they cloned `bajakota-cyber/claud-app-dev-launchpad`), rename it so it stays a read-only link to the original and frees the name `origin` for theirs:
```bash
git remote rename origin upstream
```
Explain: *"I kept a link to the original launchpad called 'upstream', so you can still look at its improvements later, but nothing of yours will ever be sent there."* Never push to `upstream`.

### Path A: they have the GitHub CLI (`gh`) and are logged in (easiest)

1. Confirm the account: run `gh auth status` and read back which username they're logged in as. Make sure it's THEM.
2. Create their repo (let them pick a name; suggest `my-launchpad`):
   ```bash
   gh repo create my-launchpad --private --source . --remote origin --push
   ```
   If this folder isn't a git repo yet, initialize first:
   ```bash
   git init && git add . && git commit -m "My launchpad" && git branch -M main
   gh repo create my-launchpad --private --source . --remote origin --push
   ```
3. Record the source so the launchpad skills know where home is:
   ```bash
   git remote get-url origin   # grab the URL
   echo "<THAT_URL>" > .claude/.launchpad-source
   ```
4. Done. Tell them what just happened in plain words.

### Path B: no `gh` CLI (use the website)

Walk them through it step by step, waiting between steps:

1. Go to **https://github.com/new**
2. Repo name: whatever they like (e.g. `my-launchpad`)
3. Set it to **Private** (recommended)
4. **Do NOT** check "Add a README" / "Add .gitignore". Leave it empty.
5. Click **Create repository**
6. Copy the repo URL (looks like `https://github.com/THEIR_USERNAME/my-launchpad.git`)

Then, in this folder (skip `git init` if it's already a git repo; rename any foreign `origin` to `upstream` first, as above):
```bash
git init
git add .
git commit -m "My launchpad"
git branch -M main
git remote add origin <THEIR_REPO_URL>
git push -u origin main
```
If git asks them to log in, the first push will prompt a browser login or a personal access token. Point them to https://github.com/settings/tokens if needed.

Finally, record the source:
```bash
echo "<THEIR_REPO_URL>" > .claude/.launchpad-source
```

**Safety checks before any push:**
- Confirm `origin` points at the USER'S repo (`git remote get-url origin`). Read it back to them.
- Never set a hardcoded username/email. If git complains identity isn't set, ask the user for their own name/email and set it for this repo only.
- If a push is rejected with "permission denied" / 403, the repo isn't theirs or they're not logged in. Stop and help them fix the login; don't work around it.

---

## Phase 4 (Local): Make it yours, no GitHub needed

If they want zero GitHub, hand off to the airgapped flow. It sets up a local "master folder" that all their projects sync from:

> "Easiest no-GitHub option: I'll set up a master folder on your computer that all your projects copy from. Run `/setup-launchpad-local` and I'll point it wherever you like (default `C:\claude-launchpad\`)."

You can invoke that flow directly, or briefly explain it and let them run `/setup-launchpad-local`. Either way, the result is a `.claude/.launchpad-source` pointing at a local folder, and no git involved.

---

## Wrapping up

However far they went, end with a short, friendly recap:
- What the launchpad is (their AI build team)
- What Phase 0 changed (if anything): it now uses their name and never acts as the original author
- The one command to remember: `/new-project` to start, or just describe what they want
- Whether they linked a source (and if so, where it lives)
- That they can re-run `/setup` anytime, or `/sync-launchpad` to pull updates once a source is linked

Keep it encouraging. The goal is that they feel oriented and a little excited, not lectured.

## Rules
- Plain language always. Assume non-developer.
- One phase at a time; wait for the user between phases.
- NEVER create a repo, push, or change git remotes without explicit yes.
- NEVER push to, commit as, or configure credentials for the original author (`bajakota-cyber` / Dakota) or anyone other than the user. The only repo that ever gets pushed to is one the USER creates and owns.
- Phase 0 edits only the personal settings it lists. Ask before editing, and say what changed afterwards.
- If `gh` or `git` isn't installed, help them install it (https://git-scm.com, https://cli.github.com) rather than failing.
