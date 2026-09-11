---
description: Code quality standards for all files
---

# Code Quality Rules

- Keep functions small and focused - one function does one thing
- Use clear, descriptive names (a reader should understand what something does without reading the implementation)
- Handle errors explicitly - don't let errors silently fail
- Add error handling on ALL network requests and file operations
- Don't repeat yourself - if the same logic exists in 3+ places, extract it into a shared function
- Keep dependencies minimal - don't add a library for something achievable in a few lines
- Write code that's easy to delete - loosely coupled, clearly bounded modules
- When something breaks, fix the root cause, not the symptom

## Timezone & Date Comparison Rules
- Timestamps stored in UTC + user events happening in local time = use a **rolling window**, not a date-equality comparison. Example: `datetime('now', '-24 hours')` instead of `date(created_at) = date('now')`.
- `date('now')` and `CURDATE()` return **server/UTC** date. If the user lives in a non-UTC timezone, "today" on the server may be "tomorrow" locally (or vice versa) for several hours every day.
- When in doubt, store timestamps as epoch/ISO UTC and do the local-time conversion at read time with the user's timezone — never by comparing date strings.
- Pattern to flag: any SQL comparing a UTC timestamp column to `date('now')`, `CURDATE()`, or a hardcoded date string without explicit timezone handling.

## Form Handler Rules
- Every form submit handler MUST have a real side effect beyond UI state (network request, DB write, webhook, email, queue write).
- A handler that only calls `setSubmitted(true)`, `setSuccess(true)`, shows a toast, or navigates — with no network call or persistence — is ALWAYS a bug. The form appears to work but silently discards the data.
- Before shipping any form, trace the data end-to-end: client handler → network → server route → storage/delivery. If any link is missing, the form is broken.

## Edge Function / Serverless Fire-and-Forget Rules
In edge runtimes (Cloudflare Workers, Cloudflare Pages Functions, Vercel Edge Functions, AWS Lambda, etc.) the runtime **kills the request context the moment your handler returns**. Any unawaited Promise — including the `void (async () => {...})()` IIFE pattern that works fine in Node — **dies mid-flight**, silently dropping whatever it was doing. This is a 100% silent data-loss pattern: no logs, no error, the work just doesn't happen.

- If the background work MUST complete (file uploads, payment confirmations, audit logs that matter, cascading API calls), **`await` it** before returning the response. Yes, it slows the response. That is the cost.
- If the platform exposes a "background work" API (`ctx.waitUntil(promise)` on CF Workers, Vercel `waitUntil()`), use it — that registers the promise with the runtime so it survives past the response.
- The pattern that's safe in Node (`void doStuff().catch(() => {})` for advisory side effects) is **NOT safe** at the edge. Audit edge handlers for any unawaited promise that touches storage, an external API, or a downstream service.
- Pattern to flag: any `void (async () => {...})()`, bare `.then()` without await, or unstored Promise inside a CF Worker / Pages Function / Edge route handler.

## Ingest Pipeline / Validate-Before-Persist Rules
When writing an ingest pipeline (file upload, webhook receiver, API import), order operations so that **persistence is the LAST step, after every gate has passed**. Otherwise a rejection (dedup, cap exceeded, validation fail) will leave orphaned writes — files on disk with no DB record, rows in a transient table that never got promoted, queue messages already acknowledged.

- Order: parse → validate bytes/shape → preflight check (dedup, cap, business rules) → write to durable storage → commit row.
- Anti-pattern (causes orphans): parse → write file → check dedup → reject (file remains on disk forever).
- For each stateful side effect, ask: "If the next step rejects this record, can I undo this side effect cleanly?" If no, that side effect should move further down the pipeline.
- Disk + DB is the most common offender. Network calls to external APIs (Stripe charges, email sends, Discord pings) are also stateful — cluster them at the end too.

## Cross-Process SQLite Rules
When two different processes (different apps, different runtimes, different languages) share a SQLite database file, write paths matter. The owning app almost always uses WAL mode (`PRAGMA journal_mode=WAL`), which keeps a separate `.db-wal` file alongside the main DB.

- NEVER write to a SQLite DB owned by another process via raw-file overwrite (sql.js + `fs.writeFileSync`, byte-level mutation, etc). The write returns success and "commits" but the next read from the owner shows the old value because the WAL pages override the freshly-written main file. Silent data loss with NO error.
- Route every cross-process write through the same library + connection setup the owning process uses. If the owner is Python+SQLAlchemy, write via a Python helper. If the owner is Node+better-sqlite3, write via a Node helper that opens with the same pragmas.
- Smoke-test final DB state from the OWNER's process, not the writer's return value. A test that only checks "did the write call succeed?" cannot detect the WAL trap.
- Pattern to flag: any `sql.js` / `fs.writeFileSync` / `Buffer` write to a `.db` file that another running process has open.

## Foreign Config Rules — A Wrong Key Is Invisible
When your code writes a config that ANOTHER application reads (`.ini`, `.conf`, `.env`, `.yaml`, `.toml`, a systemd unit, a settings row), a wrong key name — or the right key in the wrong section — is **silently ignored**. Nothing rejects it. The file gets written, the test asserting the file contains it passes, the service starts clean, and the app runs on its default. A wrong key is indistinguishable from a correct one at every level except behaviour.

- **Verify the exact key AND its section against the consuming app's own source, or against a config file that app generated itself.** Never from memory, and never from a sibling value already in your repo — a wrong key propagates by being copied. `apt-get source <pkg>`, the vendor's shipped default config, or `<tool> --help` settles it in minutes.
- **The prefix is part of the key.** `DEFAULT_LAT` and `INTERCEPT_DEFAULT_LAT` are different keys. Grep the consumer for how it actually reads config (`os.environ.get`, `settings.value`, `cfg[...]`) instead of guessing its naming convention.
- **The section is part of the key.** Qt/INI apps routinely split settings across `[Common]` and `[Configuration]`; a key in the wrong section is not a partial match, it is a no-op.
- **The name must belong to the namespace the consumer resolves in.** An ALSA device string written into a field matched against PortAudio device names does not resolve — it falls through to a default device. Same class: container vs host paths, service names vs unit names, display names vs IDs.
- **Read the value back THROUGH the app, not off disk.** Prefer the app's own status output, API, or the log line naming what it loaded. Until you have read it back, say the value was *written*, not that it is *in effect*.
- **A running consumer does not re-read its config.** Most daemons, GUI apps, editors, and dev servers with no hot-reload read config ONCE at startup. Writing the right key to the right section while the process is already up changes the file, not the behaviour — the app keeps running on the value it loaded at boot. Before reporting any result that depends on the new setting, either restart the consumer or push the value through its live API, THEN read it back. Past failure: a correct config was rendered for a running modem, nothing was restarted, and an evening of on-air testing reported "audio works but decodes are marginal" — the new mode was never loaded; five swept "modes" were all the same mode.
- **Validate THROUGH the real consumer BEFORE the write is durable.** When a validator you do not own will parse the file, your own validation is necessary but not sufficient — its rules are laxer. Make the write reversible, run the real consumer as the final gate, and roll back on failure, surfacing the consumer's own error text. Never let your validation be the only gate for a file another component must parse. Past failure: a settings endpoint passed its own checks, wrote the file, then the app's stricter loader rejected it after it had already landed — every endpoint that loaded config failed until the file was deleted by hand, taking the whole app down. (Same shape as the ingest-pipeline validate-before-persist rule, applied to config writes.)
- Pattern to flag: renderer/templating code that emits a third-party app's config where no test compares the emitted key+section against that app's source, and nothing reads the value back; a config write whose success is reported without restarting/reloading an already-running consumer; a settings write gated only by the writer's own validation with no reversible run-the-real-consumer step.

## Deploy/Sync Manifest Rules — A Hand-List Cannot See New Files
Any deploy/sync tool whose file manifest is a hand-maintained allow-list (an enumerated `DEPLOY = [...]`, a hardcoded rsync include list, a "files to push" array) silently drops every file added after the list was last edited — and worse, its own "checking for missing files" report says nothing is missing, because it only checks the files it already knows to look for. A stale list is invisible until a genuinely new file crash-loops the remote.

- Reconcile the manifest against a REAL WALK of the source tree, not an enumerated list. Glob the known package roots (`*.py` under each package dir, all modules under `station/api/`, etc.) and diff that against what is already on the remote — never trust a list a human has to remember to update on every new file.
- FAIL LOUDLY when a package directory the tool knows about is absent or incomplete on the remote side. Never report "nothing missing" from a manifest that structurally cannot see files outside itself.
- Pattern to flag: a custom deploy/rsync/scp script with a hardcoded file list and a completeness check that iterates that same list. Past failure: `station/api/` (11 modules) was never added to a `deploy.py` allow-list from the day the directory was created; the first new file added under it was silently never deployed, the dashboard crash-looped on the missing import, and the deploy tool reported a clean, complete deploy — while also masking two other files two commits stale on the remote.

## Reconfigure-Is-Recompute Rules (schedulers, cron, queues)
An `enable` / `apply` / `reload` call on a scheduler is usually a **full recompute**, not a field edit. Already-armed items can vanish — most often the imminent one, because it no longer clears a minimum lead-time buffer. The response still returns `ok` with a healthy non-zero count.

- Before changing a scheduler/cron/queue parameter, ask whether the imminent item survives the recompute. If it fires soon, do not touch the scheduler for a marginal gain.
- Diff the resulting item list against what was armed before. `status: ok` plus a non-zero count is NOT proof the item you cared about survived.
- Pattern to flag: an apply/reload handler that rebuilds a schedule from scratch and returns only a count — no diff, no `dropped` list, no warning for previously-armed items that were removed.

## Stub Function Rules
- A function whose entire body is `log_info(...) + return` (or `pass`, or `return undefined`) when callers treat it as a real side-effecting operation is a silent-broken stub. Tests pass, lint passes, CI passes — production silently does nothing.
- Either implement for real, leave the function entirely unimplemented (so callers see an obvious gap), or raise `NotImplementedError` / `throw new Error('not implemented')` so the failure is loud and immediate.
- Pattern to flag: any function with a one-line body that's just a log/print/console.log statement.

## Reactive UI State Commit Rules (Streamlit, React, Vue)
In reactive-UI frameworks, widget `value=` props (Streamlit `st.text_input(value=...)`, React controlled `<input value={...}>`) do NOT always commit synchronously back to session_state / store / signal during the same render pass. The committed value lags by one rerun.

- **Never compute counters, labels, or auto-numbering by reading state that is being edited in the SAME render cycle.** Past failure: an "Option N" auto-numbering scheme that counted existing labeled sections to pick the next number — when the user added a 3rd unlabeled section, the count was stale and labeled it "Option 4" instead of "Option 3". Fix: count via render-order index (a local counter incremented inside the render loop), not by re-reading state.
- **Never read `session_state[other_widget_key]` to drive a render decision when `other_widget_key` is being edited in the same pass.** Restructure so the dependent widget renders after the edit commits, or pass the live value through a parameter.
- Pattern to flag: any `len([x for x in items if x.label])` or equivalent "count what's labeled" pattern used to compute the NEXT sequence number in a reactive UI render loop.

## Streamlit-Specific Rules
- NEVER use `use_container_width=True` on display components (`st.dataframe`, `st.data_editor`, `st.plotly_chart`, `st.altair_chart`, `st.pyplot`, `st.image`) — use `width="stretch"` instead. `use_container_width` is deprecated and will be removed after 2025-12-31.
- `use_container_width=True` on interactive widgets (`st.button`, `st.text_input`, etc.) is still valid — only display components are affected.

## Observable State & Health Check Rules
- **Liveness is not health.** `systemctl is-active`, an open TCP port, a successful connect, a process visible in `ps`, or a 200 from `/healthz` prove the process EXISTS — not that it is doing its job. An app frozen behind a modal dialog, deadlocked, or stuck in a retry loop passes every one of those checks.
- Every health check MUST assert on at least one field that only a *working* application could produce: a live tuned frequency, a recent heartbeat timestamp, a non-zero processed count, a last-successful-job time. Treat `0`, `null`, unset, or "older than N minutes" as UNHEALTHY — not as "no data yet".
- **Command, then read back.** After any command that changes state on a device or an external system (CAT frequency set, GPIO write, motor position, relay toggle, third-party config update), read the state back and compare it against what was commanded. Alert on mismatch. "The command returned success" is not "the state changed".
- **Never report unobservable state as fact.** If the code (or you) cannot read the actual state, say what was commanded, not what is true. Prefer building a cheap monitor/probe over reasoning about what the hardware "should" be doing.
- Pattern to flag: a health endpoint or status indicator whose only inputs are process/socket liveness; any state-changing command to hardware or a third party with no read-back verification.

## Diagnostic & Check-Script Rules — A Failed Measurement Is Not a Negative Result
Any script that answers a question ("was I heard?", "did it decode?", "is the file there?", "how many rows?") has THREE possible outcomes, not two: **succeeded-with-data**, **succeeded-and-genuinely-empty**, and **failed-to-run**. Collapsing the third into the second produces a false negative that gets acted on. An instrument that cannot report its own failure is worse than no instrument.

- Error paths and empty-result paths MUST emit distinct output. Never let an exception handler, a timeout, or a non-200 response fall through to the same "nothing found" string a real empty result produces. Print `CHECK FAILED: <reason>` and exit with a distinct code.
- **Exit codes are not results.** A non-zero exit proves the process errored — it says nothing about what it found. Read stdout/stderr content before concluding anything. A crash while *printing* a successful finding (classic: `UnicodeEncodeError` printing non-ASCII on a Windows console, whose default encoding isn't UTF-8) exits 1 while the data existed. Set `PYTHONIOENCODING=utf-8` / `encoding='utf-8'` on any script that may print non-ASCII.
- **A broken query is not a negative answer.** HTTP 403/429, auth failure, DNS failure, timeout, wrong endpoint, or an unparseable response means the check is broken — report "unknown", never "no". (403 from a default `urllib`/`requests` User-Agent that a browser or `curl` gets 200 on is a common trap: set an explicit User-Agent.)
- **Never truncate the error signal.** Piping a command through `head`, `tail -0`, `| tail -n N`, or `2>/dev/null` can discard the one stderr line saying it failed. If you must limit output, keep stderr and keep the exit status (`set -o pipefail`).
- **Two independent paths need two independent tests.** When a system has separate directions or halves — read/write, capture/playback, in/out, encode/decode, upload/download, send/receive — verifying one is NOT evidence about the other. They typically use different code paths, buffers, or clocks. Never declare a bug fixed after measuring only the direction that was easiest to measure. Past failure: a sound-card sample-rate bug was twice declared fixed on the strength of a correct capture measurement while playback stayed 3% slow — separate clocks.
- **This rule fires when you WRITE the command, not when you read the result** — by reporting time the evidence is already destroyed. Treat as banned by default in any command whose answer will be acted on: `2>/dev/null`, `| head` / `| tail -n N` applied to the command's own diagnostics, `-q`/`--silent` on the thing being measured, and `command -v`/`which` as proof of absence (PATH-dependent — resolve absolute paths or call the app's own installed-check). If you need less output, filter stdout and keep stderr.
- **A weaker instrument never overrules a working one.** When an ad-hoc spot-check disagrees with the application's own checker, the spot-check is the prime suspect — find out WHY they disagree before reporting either. Past failure: `command -v` reported binaries MISSING that were sitting in `/usr/sbin` (not on that user's PATH), contradicting the app's checker, which was right.
- **Informational-sounding flags can still claim hardware.** `rtl_433 -R list`, `rtl_test` with no args and similar "just print something" invocations open the device and may never exit — then the next check reports a false negative caused by your own held handle. Pass the explicit one-shot/exit flag, bound the run, and verify the device is free before blaming contention on anything else.
- Pattern to flag: an `except:` / `catch` block that returns the same value as the empty-result case; any checker whose "not found" message can be reached without a successful query; any pipeline that swallows stderr on a command whose failure matters.

## Internal Contradiction Is the Fastest Localiser
When two views of the same data disagree, the disagreement IS the bug — and it localises the fault far faster than reasoning about either view alone. Hunt for contradictions deliberately instead of waiting to notice one.

- Before publishing a transcription, summary, or diagnosis, cross-check it against another fact drawn from the same source. A per-row detail that contradicts your reading of the header means your reading is wrong, not that the document is sloppy. Past failure: a schedule was recorded as "JS8 owns 0100-0300" while a line transcribed in the same pass said "Winlink handshakes start at 0135Z" — impossible under that reading, and the contradiction went unread.
- Two UI panels, two API responses, or a log and a database implying different event sequences is a finding, not noise. Report the contradiction; do not quietly pick the view that fits the current theory. Past failure: a dashboard showed four received messages beside "nobody heard you in 24h" — the operator spotted it, the agent did not.
- Extracted PDF/HTML text loses table geometry. A run of adjacent time ranges or values on ONE line is a COLUMN HEADER, not a sequence of identical blocks. When structure carries meaning, render the page as an image and look at it.
