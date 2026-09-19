---
description: Security rules that apply to all code in the project
---

# Security Rules

- NEVER hardcode API keys, tokens, passwords, or secrets in source code
- ALWAYS use environment variables for sensitive configuration (process.env, os.environ, etc.)
- ALWAYS create a `.env.example` file with placeholder values (never real secrets)
- ALWAYS ensure `.env` is in `.gitignore` BEFORE creating any `.env` file
- ALWAYS validate and sanitize user input before using it in queries, HTML, or commands
- NEVER use `eval()`, `innerHTML` with user data, or string concatenation for SQL queries
- ALWAYS use HTTPS for external API calls
- NEVER log sensitive information (passwords, tokens, full credit card numbers)
- ALWAYS use parameterized queries for database operations
- When adding authentication, ALWAYS hash passwords (use bcrypt or argon2, never MD5/SHA1)
- When a screening/compliance/safety filter (content moderation, auth gate, spam/abuse check, legal-compliance guard, encrypted-content refuser) hits an ERROR while evaluating input, FAIL CLOSED — reject or hold the input, never pass it through unscreened. An exception inside the screener must not become an open door.
- Stress-test any such filter in BOTH error directions before shipping: false positives (legitimate input wrongly blocked) AND false negatives (prohibited input wrongly passed). Testing only the block path proves nothing about what leaks through — the two directions use different branches and fail independently.
