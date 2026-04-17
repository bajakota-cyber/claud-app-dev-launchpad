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

## Streamlit-Specific Rules
- NEVER use `use_container_width=True` on display components (`st.dataframe`, `st.data_editor`, `st.plotly_chart`, `st.altair_chart`, `st.pyplot`, `st.image`) — use `width="stretch"` instead. `use_container_width` is deprecated and will be removed after 2025-12-31.
- `use_container_width=True` on interactive widgets (`st.button`, `st.text_input`, etc.) is still valid — only display components are affected.
