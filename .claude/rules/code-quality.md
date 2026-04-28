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

## Streamlit-Specific Rules
- NEVER use `use_container_width=True` on display components (`st.dataframe`, `st.data_editor`, `st.plotly_chart`, `st.altair_chart`, `st.pyplot`, `st.image`) — use `width="stretch"` instead. `use_container_width` is deprecated and will be removed after 2025-12-31.
- `use_container_width=True` on interactive widgets (`st.button`, `st.text_input`, etc.) is still valid — only display components are affected.
