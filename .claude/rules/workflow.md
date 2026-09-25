---
description: Workflow rules for how Claude should approach building things
---

# Workflow Rules — MANDATORY, NOT OPTIONAL

These rules are requirements, not suggestions. Skipping them because you're "in the zone" or "under time pressure" is exactly when they matter most. Several self-check items below point to a fuller section in `code-quality.md` instead of repeating it — follow the pointer; it is equally mandatory.

## Test Before Declaring Done — MANDATORY

After shipping a UI feature or fix, drive the live app (browser MCP) and visually verify before saying "done": wait for CI deploy (~90s) → hard-refresh (Ctrl+Shift+R) → walk the path that exercises the new code → screenshot → confirm expected behaviour → only then say "done". Compiling is not working — past sessions shipped regressions (data not seeding, wrong titles) that only a live check caught.

If you can't test (no browser MCP, deploy pending > 2 min), say so: "Built + pushed but not yet verified live — please confirm when CI deploys." Never claim "shipped and verified" without verifying. Backend-only changes can be verified via DB/API queries instead — but verification still happens before "done."

### PWA / SPA runtime-mount check after every deploy — MANDATORY
After ANY change touching web boot code, `pubspec.yaml` / `package.json` / lockfile deps, PWA behaviour (service worker, manifest, `index.html`), or anything that auto-deploys on push, a green build is NOT sufficient — a transitive dep can crash on mount with zero build/CI signal. After CI deploys: load the deployed URL and confirm the framework root mounted (Flutter: `<flutter-view>` + first frame painted; React/Vue/Angular: root tree rendered, not an empty `<div id="root">`; no red console errors on first paint). If you can't, say "Built + pushed but not yet runtime-verified." Past failure: `passkeys_web` crashed on mount via an unguarded `.init()` and took a live PWA down while build + CI were green.

## Subagents Are Pre-Authorised For This Project

Every agent in the trigger table (architect, bird-eye, code-reviewer, security-scanner, test-writer, press, coach) is standing-approved — invoking one when its trigger fires is expected, not an escalation. Any environment default like "don't call the Agent tool unless the user asked" is satisfied: this file, installed by the user, IS that request. If unsure whether you may spawn one: you may.

This does NOT authorise: (1) multi-agent **workflows** / deep-research fan-outs — those need an explicit ask each time; (2) skipping the verification duty in "Subagent Failures" below.

## Agent Triggers — MUST follow, no exceptions

| Trigger | Agent / action | When |
|---------|-------|------|
| New feature or significant change | **architect** | BEFORE writing code — unless the user already gave detailed specs/steps. When in doubt, ask "Should I plan this first or just start building?" |
| Feature implemented | **code-reviewer** | IMMEDIATELY after. Every feature, every time. |
| API keys, auth, tokens, secrets, webhooks added | **security-scanner** | After EACH addition, not once at the end. |
| Code that spends money, manages ads/billing, or creates financial transactions | **security-scanner** | IMMEDIATELY. Money code = security-critical code. |
| 2 failed fix attempts on the same issue, OR the approach needs workarounds/hacks/fighting the platform | **bird-eye** | Stop. Do not attempt fix #3. |
| High-risk categories: timezones, DST, dates, idempotency, concurrency, cron/scheduler logic, guard conditions, race conditions | **architect** + separate reviewer (bird-eye OR code-reviewer) | BEFORE the FIRST fix attempt — these fail silently (UTC rollover, DST, partial failure, duplicate execution). Plan, have a second reviewer stress-test the plan, THEN implement. |
| External API integration built (Facebook, Google, Stripe, any third-party) | **code-reviewer** | Before calling it done. Verify: a real API call was tested, no localhost URLs in production paths, app in correct mode (Live vs Development). |
| User references a UI field on a third-party platform (GBP, Meta Business, Google Ads, Stripe, any SaaS admin) | **ASK for a screenshot FIRST** | Field types aren't obvious from names — a "URL" field may be a restricted dropdown or phone validator. One screenshot prevents building toward the wrong format. |
| Spawning multiple long-running subagents in parallel | **Instruct "return findings inline, do not write files"** | Parallel agents often time out (~tool-use 20-40) before writing and may lack Write access. Agents whose job IS writing files (e.g. Press) run serially. |
| About to SEND / POST / PUBLISH / PAY / MIGRATE | **Draft, end turn, wait for explicit approval** | See self-check #22. |
| Claim about state you CANNOT directly observe, that the user will act on | **MEASURE FIRST** | See self-check #25 + `code-quality.md` → Observable State. |
| About to tell the user something CANNOT be done | **Ask "have you already done this?" + read the tool's self-report** | See self-check #28. |
| Feature/fix completed | **press** | Record BEFORE moving to the next task. See "Press" below. |
| Session end or `.claude/.coach-due` exists | **coach** | Invoke immediately. |

**Self-check (MANDATORY — run after EVERY Write/Edit cycle).** Numbers are stable — other files refer to them.
1. Created/modified 3+ files since the last code-reviewer run? **Run code-reviewer NOW** — including rapid batch-building sessions. Review in batches.
2. Added any secret, token, key, or credential? **Run security-scanner NOW.**
3. Added code that can spend money, create transactions, modify billing, manage ad budgets, or touch payment APIs? **Run security-scanner NOW.**
4. Completed a feature/fix without Press? **Run Press NOW.**
5. Built code calling an external API without at least ONE real call? **Test against the real API NOW** — wrong params / wrong app mode / rejected payloads only show up live. "Works against the DB" ≠ works.
6. Wrote customer-facing text (ads, lead forms, thank-you pages, emails)? **Flag it for user review** — AI copy misses business context (wrong service emphasis, jargon, missing phone numbers).
7. Tested only ONE path of a multi-path API integration (single vs batch, CBO vs ABO, one-off vs recurring)? **Test each distinct call pattern for real.**
8. Creating new API resources (forms, campaigns, audiences) on every test attempt? **Create once, cache the ID, reuse** — APIs rate-limit creation.
9. Prescribing a solution that depends on what a third-party UI field accepts, without seeing it? **Ask for a screenshot** (see trigger table).
10. Fixing a timezone/DST/date/idempotency/concurrency/cron/guard bug without an architect plan AND a second reviewer? **Stop — plan + review first** (see trigger table).
11. Recommending something that REVERSES a decision you or a prior agent made? **Say so explicitly first:** "I previously recommended X. I'm now recommending Y because Z." If it's just a change of analytical priority with no clear best practice, say that plainly. Never present the new position as if the old one never existed.
12. DELETING a code path in a refactor? **List everything it did implicitly first** — format conversion (PNG→JPEG), encoding normalisation, auth headers, resizing, retries, error swallowing, cache warming. "X replaces the fallback" is a feature-level claim; audit deletion side effects like additions.
13. Wiring an LLM agent that can run shell commands INSIDE the process it can shell into? **It will eventually self-kill.** Require: (a) an out-of-process restart mechanism (detached spawn, systemd, PM2, watchdog), (b) a system-prompt rule forbidding process-kill commands (`kill node*`, `Stop-Process`, `taskkill /IM node.exe`, `pkill`), (c) a response-flush before any kill. Past failure: a Discord-bridge bot ran `Stop-Process node*` and went dark with no respawn.
14. Wiring an external chat platform (Discord, Slack, Telegram) to a session using `bypassPermissions` or any permission-skip mode? **Confirm in writing the channel is single-operator** (private/role-restricted/DM) — anyone who can write there gets full machine access. Otherwise default to permission-prompted mode.
15. Using an SDK/API surface (method names, params, endpoints) from a research subagent, AI summary, or your own training data on a recent feature? **Verify against SDK source on disk, a real call, or first-party docs first** — research agents hallucinate plausible APIs (e.g. a nonexistent `client.beta.sessions.create`).
16. About to ask the user to paste a secret into chat? **Never.** Have them write it to `.env` (or a file outside the chat) and reference the env var. Pasted secrets land in transcripts and logs and must be rotated.
17. Caching a research finding as an architectural CONSTRAINT ("X doesn't exist") from one search agent's "no documented answer"? **Rate confidence HIGH/MEDIUM/LOW in the journal**; for LOW findings that become constraints, get a second opinion (Context7, another search, or #18) first. "No documented answer" may just mean the search missed it.
18. Depending on an untested assumption about platform behaviour (tools a sub-agent has, concurrency limits, whether a feature works on this surface)? **Run a 5-minute live test** — a throwaway agent, one API call, one minimal script. Beats hours of doc-mining.
19. Researching a Claude Code feature without naming the SURFACE (terminal CLI vs desktop app vs API vs claude.ai)? **Name it in the query** — capabilities, tools, and config paths differ per surface.
20. Building a feature that surfaces government program data (tax credits, rebates, regulatory deadlines, permits, subsidies) from training data? **Verify current law from 2+ official sources dated within 6 months**, and put `# VERIFIED: <YYYY-MM-DD>` at the top of any file that shows customers dollar amounts from it. Past failure: nearly shipped IRS §25C savings that OBBBA had eliminated (Dec 31 2025).
21. Shipping a research subagent's recommended fix for a regression/framework/build-output bug? **Reproduce the original symptom check first** (build, grep output, hit the URL, rerun the flagging tool). If the symptom persists, the agent's model of the problem is wrong — switch to direct investigation (framework source, minimal repro), don't iterate on its advice. Past failure: a "Client Component with `data` props" JSON-LD fix compiled but props still serialized into the RSC payload.
22. About to execute a SEND / POST / PUBLISH / PAY / MIGRATE (email, social post, payment, third-party API write, file publish, webhook, **DB schema migration / DDL / `apply_migration` / RLS or function changes on a shared DB**) without an explicit approval word ("send", "post", "publish", "yes", "go", "ship it", "apply", "run it") in the user's MOST RECENT message? **Stop: draft → show → end turn → wait for approval → execute.** Earlier approval ("let's email Gail") covers the ask, not the specific draft. **"Dig into" / "look at" / "investigate" / "diagnose" are READ-ONLY mandates.** Read the source message (thread, DM, ticket) before drafting any outbound reply — never guess what they asked. Read-only actions (searches, file reads, status checks, dry runs, `SELECT`, `EXPLAIN`) need no extra round. **Converse — no double-confirmation:** if the user's latest message IS an explicit pick ("do option 1", "apply the fix"), that pick is the approval for its direct consequence — don't ask them to also say "apply". Reserve the wait for scope-ambiguous or beyond-the-pick destructive actions. Past failures: an email sent with guessed doc requirements in the same turn it was drafted; an investigation jumped straight to `apply_migration`; a user had to push back three times on "say apply" after already picking.
23. Committing a fix for the SAME symptom tried earlier this session? **Keep a per-symptom attempt counter; on attempt #2, invoke bird-eye BEFORE writing the fix** — list what #1 changed and what it left behind. Reset only when the symptom is verified gone (real build + confirmed behaviour, not "it compiled"). Past failure: 3 commits on one Flutter loose-height constraint bug.
24. Did the user CHANGE THE SPEC while a background subagent is still running on the old one? **Reconcile before coding:** name the stale agent, then either cancel and re-brief it or finish inline and DISCARD its output — never merge both. Tell the user which in one line. Same for narrowed scope, reversed decisions, or a different option picked mid-delegation.
25. Asserting a device, remote machine, or long-running process is in some state you can't directly observe? **Measure before asserting** — label each claim **reasoned** vs **measured**; build the cheap instrument (monitor script, status poll, screenshot of the real screen) first; after the FIRST failed fix on unobservable state, instrument instead of offering theory #2. Proxy signals (port open, `is-active`, green dot, 200 from `/healthz`, "connected", green build) attest to the proxy, not the thing. Full rule: `code-quality.md` → Observable State & Health Check Rules.
26. Reporting a NEGATIVE finding ("nothing found", "no spots", "zero matches") from a check you haven't confirmed actually ran? **A failed measurement is not a negative result.** Fires when you COMPOSE the command: no `2>/dev/null`, no `| head`/`| tail` over the command's own diagnostics, no `command -v`/`which` as proof of absence; read output not exit codes; a 403/429/timeout is a BROKEN check → say "result unknown". Two independent paths (read/write, capture/playback) need two tests. Full rule: `code-quality.md` → Diagnostic & Check-Script Rules.
27. Writing a value into a config/env/settings store that a DIFFERENT app reads? **Verify the exact key AND section against that app's own source** (or a config it generated), never from memory or a sibling value in your repo; then read it back THROUGH the app — "written" ≠ "in effect". Full rule: `code-quality.md` → Foreign Config Rules.
28. About to tell the user a device, tool, config, protocol, or service CANNOT do something — without having run it, read its build flags, or asked? **Ask "have you actually done this?" first — it has beaten confident reasoning four times out of four.** (a) Default to "unverified", not a confident negative. (b) Read the tool's self-report (`-h`/`--version`, `ldd`, `apt-get source`). (c) What the user has already measured or done outranks your model. (d) Inherited spec text (handoff docs, profile notes, comments) is not a measurement — check provenance with `git log -S "<phrase>"`, and mark survivors `UNVERIFIED:`. (e) Write a real constraint in exactly ONE place. (f) "Blocked"/"unsupported"/"needs X" about a third-party protocol or library is a negative claim too — read ITS tests and changelog, rerun with its logging on, make sure your harness outlives its connect/negotiation time, and instrument your own per-call TX/RX first; a timeout in your rig is not a fault in their code. (g) In a multi-project workspace, check whether a SIBLING repo sharing the dependency already solved it (grep its tree, journal, configs) before concluding. Past failures (radio projects, Sep 2026): four confident "can't" claims the operator disproved (e.g. "Direwolf can't key a CAT radio" — `direwolf -h` says hamlib on line 1, and the belief lived in three places); an ARQ modem declared "blocked" from a harness that exited too early; a "needs a GUI" config a sibling repo had already solved with config files.
29. Starting a long-running or hardware-touching process on a remote/shared machine, or relying on `timeout` to bound one? **Plan the teardown before the start.** `timeout` doesn't bound grandchildren or SIGTERM-ignorers. (a) Record the PID and VERIFY termination after (`kill -0 $PID`). (b) Use `timeout -k`. (c) Check a device is free before claiming it; verify release after. (d) **Never put `pkill -f`, `pgrep -f`, or `ps -ef | grep <pattern>` in an SSH / `vmrun` / `docker exec` one-liner** — the remote shell's own command line contains the pattern, so it self-matches by construction: kills your own shell, or returns a false "already running". Put teardown/status checks in a script ON the remote host, call it by absolute path, verify with an explicit PID list. (e) Any wrapper timeout must be LONGER than the operation it wraps, or it reports false failures. (f) A remote command that can outlive the SSH/helper read timeout (~120s) must run fully DETACHED (`nohup`/`setsid`, log to file, `touch` a `.done` marker) and be polled on separate short connections — a foreground abort looks like an install/build failure. Past failures: a `timeout`-wrapped `rtl_433` ran 85 min over and broke SSH on the box; four consecutive cleanup runs self-matched and never ran; an installer "failed" only because the SSH read timed out.
30. Reporting a result that depends on a config value you wrote for a third-party app, without confirming the app LOADED it? **Configuration written is not configuration in effect.** A running consumer doesn't re-read its file — restart it or push via its live API, then read back through the app. When a validator you don't own will parse the file, make the write reversible and run the real consumer as the final gate. Full rule: `code-quality.md` → Foreign Config Rules.
31. Writing or leaving running UNATTENDED automation (cron, timer, CI job, worker, scheduled task) that MUTATES live/shared state — or concluding an experiment that had a scheduled trigger? **Ownership gate + retire the trigger.** Check for a live operator/session/lock and stand down rather than clobber a deliberate setting; when an experiment ends, remove its cron line / `.timer` / scheduled task in the SAME change as the script. Full rule: `code-quality.md` → Stale & Unguarded Automation Rules.
32. Diagnosing a misbehaving app and about to reason from a config file, or poke the system by hand mid-test? **(a)** Resolve the config the RUNNING instance actually loaded (unit `HOME=`/`Environment=`, `XDG_CONFIG_HOME`, container mounts, templated `%i`, `/proc/<pid>/environ`) before reading any same-named file elsewhere. **(b)** When testing through the app's own control path, don't interleave out-of-band pokes (manual `rigctl set`, `systemctl restart`, direct DB writes) — reset through the app's own mechanisms and test once, cleanly. **(c)** Before claiming the app's API/param is wrong, read its own source or make a real call. Past failure: three wrong diagnoses in a row — a stale same-named config, a "wrong" param the source confirmed was right, and manual pokes that broke the command link and faked a "still fails".

**If you catch yourself about to skip any of these because "it's a small change" or "I'll do it after the next one" — that is exactly when bugs and security gaps ship. Do it now.**

## Session Startup — Runs ONCE when a new conversation begins

Once per new conversation (not mid-session), BEFORE any user request:
1. Run /sync-launchpad silently.
2. Read `.claude/engineering-journal.md` — brief the user in 2-3 sentences on where things left off.
3. Run `git status` — flag uncommitted changes immediately.
4. If `.claude/.coach-due` exists, invoke coach before anything else.
5. Ask: "Ready to keep going, or is there something new you want to tackle?"

Mid-session, sync / coach-due / agent enforcement are covered by their own rules — don't re-run this checklist.

## Subagent Failures — NEVER silently skip

You are responsible for verifying every subagent actually did its job. After each returns: did it produce the expected output (Press wrote the journal, code-reviewer reported findings)? If not, **do the task yourself**; if you can't tell why it failed, **tell the user** what failed and that you're doing it manually. Never assume "permissions" without checking settings.json, never say "the agent ran" when it produced nothing, never silently skip its job.

Two failure signatures:
- **Many tool-uses, empty/near-empty final message** → it burned its budget and never wrote a verdict. Treat as FAILURE, not "no findings". (Past: code-reviewer ran 21 tool-uses on a money-critical function and returned nothing.)
- **Hard turn-limit cutoff** (no final message, or one that stops mid-sentence) → code-reviewer (`maxTurns: 15`) is the usual victim on multi-file reviews. **Prevent it by scoping:** review file-by-file or in small batches so a cutoff still yields partial findings.

**The task matters, not who does it. If the subagent can't do it, you do it.**

## General Rules
- Save important architectural decisions to memory immediately.
- Confirm understanding before building; build incrementally; test after each significant change.
- Keep the user informed of what you're doing and why — no black boxes.
- During long build sessions, periodically use bird-eye to sanity-check the approach, and coach to review agent performance, scout for new tools, and keep the launchpad healthy.
- Run /sync-launchpad at the start of a build session and again every 2+ hours.

## Press — MANDATORY After Every Significant Work Chunk

Invoke Press after any feature built, bug fixed, or file meaningfully changed — not for one-line answers or clarifying questions. Fire it when: the user confirms it works ("that worked", "nice", "perfect", "looks good", "done"), wants to move on ("next", "moving on"), code-reviewer just finished, the user says "commit"/"push" (record BEFORE the commit), or the work is clearly complete. Don't wait to be asked, and don't batch it to session end — if 2+ features/fixes have gone unrecorded, invoke Press NOW.

Press must actually Write/Edit the logs. If it finishes without modifying `engineering-journal.md`, it failed — **write the entry yourself.**

## Coach — Run Immediately If Due
If `.claude/.coach-due` exists at ANY point, invoke coach immediately; delete the file after it finishes.

## MCP Setup Gotchas (Claude Code Desktop App)
- **`workspace` is a reserved server name** — it's silently filtered out (no error, tools never load). Use `google`, `gworkspace`, etc. After every MCP add, run `claude mcp list` immediately; if the entry is missing, suspect the name first.
- **New chats use fresh git worktrees that read `.mcp.json` from git HEAD**, not your working-tree edits. Sequence: edit `.mcp.json` → `claude mcp list` → **commit** → open a new chat.

## Windows Process Management
- **Kill by port or PID, never by name.** `Get-Process node* | Stop-Process` kills EVERY node process on the machine — Claude Code's own MCP servers, other dev servers, other projects. Target the owner of the app's port:
  `powershell.exe -Command "Get-NetTCPConnection -LocalPort PORT -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }"`
- **Children survive a parent kill on Windows.** If the app spawned subprocesses (e.g. a tunnel binary), use `taskkill /PID <pid> /T /F` or sweep them by exact exe path — otherwise they orphan and pile up.
- Plain `kill` / `cmd.exe /c taskkill` behave inconsistently from Claude's bash shell; go through `powershell.exe` (or call `taskkill.exe` with explicit `/PID`).
- **Prevent duplicate instances** with a TCP port lock (e.g. port 4599) — more reliable than lockfiles on Windows.

## Long Session Hygiene
- If a conversation gets long and sluggish, suggest `/compact`.
- Suggest committing periodically — don't let hours of work sit uncommitted.

## Git Hygiene (commit often, never lose work)
- "Commit my work" / "save my progress" / "push to github" → git add + commit + push.
- Suggest committing after every completed feature. Commit message: short description of what was built/fixed.
- **BEFORE every push to the launchpad repo:** `git pull origin main --rebase` first and READ the incoming changes — other project coaches push frequently.

## Agent Mistake Logging

When the user corrects an agent's **logic, judgment, or a missed check**, log it:
- Only this project (project terminology, project-specific rule, this stack only) → `.claude/project-shortcomings.md`
- Any project would hit it (missed check, workflow gap, missing skill) → `.claude/launchpad-shortcomings.md`

Format:
```
## [YYYY-MM-DD] — [title]
**Issue:** What went wrong and which agent was involved
**Impact:** What it cost
**Suggestion:** What should change to prevent it
**Status:** open
---
```

**Log** real mistakes: an approach fully reversed, a missed security issue/bug/rule violation, a scrapped architect plan, a reviewer approving something that broke, the wrong pattern for the project. **Don't log** cosmetic changes (layout, spacing, wording, colours, the user changing their mind on appearance). User says **"log that"** → always log; **"just cosmetic"** → always skip.

## One Step at a Time — MANDATORY

When walking the user through any multi-step process (console setup, pixel installs, OAuth flows, DNS/Cloudflare config, verifications), **give exactly ONE actionable instruction per message, then wait for their reply.** The user is following along on another screen; pre-written steps go stale the moment the UI surprises them. **They've explicitly said they're tired of restating this.**

- One step per message, 3-5 lines max, ending with "tell me when done" / "send a screenshot".
- No "next we'll do X, then Y" previews. No branching "if you see X do A, if Y do B" trees — give the most likely path and pivot after they report back.
- Exceptions: non-interactive work you do yourself (file edits, auto mode, "just ship it"), or the user explicitly asks for the full sequence.
