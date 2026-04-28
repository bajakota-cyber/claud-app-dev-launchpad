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

## Cross-Process SQLite Rules
When two different processes (different apps, different runtimes, different languages) share a SQLite database file, write paths matter. The owning app almost always uses WAL mode (`PRAGMA journal_mode=WAL`), which keeps a separate `.db-wal` file alongside the main DB.

- NEVER write to a SQLite DB owned by another process via raw-file overwrite (sql.js + `fs.writeFileSync`, byte-level mutation, etc). The write returns success and "commits" but the next read from the owner shows the old value because the WAL pages override the freshly-written main file. Silent data loss with NO error.
- Route every cross-process write through the same library + connection setup the owning process uses. If the owner is Python+SQLAlchemy, write via a Python helper. If the owner is Node+better-sqlite3, write via a Node helper that opens with the same pragmas.
- Smoke-test final DB state from the OWNER's process, not the writer's return value. A test that only checks "did the write call succeed?" cannot detect the WAL trap.
- Pattern to flag: any `sql.js` / `fs.writeFileSync` / `Buffer` write to a `.db` file that another running process has open.

## Stub Function Rules
- A function whose entire body is `log_info(...) + return` (or `pass`, or `return undefined`) when callers treat it as a real side-effecting operation is a silent-broken stub. Tests pass, lint passes, CI passes — production silently does nothing.
- Either implement for real, leave the function entirely unimplemented (so callers see an obvious gap), or raise `NotImplementedError` / `throw new Error('not implemented')` so the failure is loud and immediate.
- Pattern to flag: any function with a one-line body that's just a log/print/console.log statement.

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

## Streamlit-Specific Rules
- NEVER use `use_container_width=True` on display components (`st.dataframe`, `st.data_editor`, `st.plotly_chart`, `st.altair_chart`, `st.pyplot`, `st.image`) — use `width="stretch"` instead. `use_container_width` is deprecated and will be removed after 2025-12-31.
- `use_container_width=True` on interactive widgets (`st.button`, `st.text_input`, etc.) is still valid — only display components are affected.
