# Git Identity Rules — Never Commit With a Personal Email

Your git commit email is baked into **every** commit (author AND committer) and rides to
GitHub the moment you push. On a public repo it is then readable by anyone with one
`git log`. A personal inbox exposed this way is a privacy leak, and a history rewrite —
painful, and impossible to fully guarantee once the repo has been forked or cloned — is the
only way to undo it. Get the identity right BEFORE the first commit, not after.

## The rule
- **Set every repo's `git config user.email` to your GitHub account's NO-REPLY address** —
  never a real inbox. The no-reply looks like `<ID>+<username>@users.noreply.github.com`
  and is shown at GitHub → **Settings → Emails → "Keep my email addresses private."** It
  can't receive mail, exposes nothing personal, and still links commits to your account.
- **Set `user.name` to a handle you're fine being public** — not your real name or a
  callsign if you want to stay pseudonymous. It's public on every commit too.
- **Turn on both GitHub email guards once per account** (Settings → Emails): *"Keep my email
  addresses private"* AND *"Block command line pushes that expose my email."* The second
  makes GitHub itself reject a push that would leak a **registered** account email.
- **The push-block does NOT catch an email that isn't registered on your account.** An old
  gmail, a work address, any inbox not on your account will still push through if it sits in
  your git config. For those, the git config is the *only* guard — so set it correctly.

## Set it per repo (do this in every clone)
```bash
git config user.name  "your-handle"
git config user.email "<ID>+<username>@users.noreply.github.com"
```
Prefer per-repo over global: a global identity applies to *every* repo including work ones
that may need a different address. Set a global no-reply only if all your work uses it.

## Patterns to flag
- Any repo whose `git config user.email` is a real inbox (`@gmail.com`, `@company.com`, an
  ISP or work address). Fix it before the next commit.
- A repo **about to go public** whose *history* already contains a personal email: it must be
  scrubbed (`git filter-repo --mailmap` → force-push) **before** it goes public. A rewrite
  after exposure cannot reach forks, clones, or GitHub's cache. Past incident (2026-09-17): a
  private gmail sat in a *public* launchpad repo's history and had to be scrubbed across three
  repos and force-pushed; the fix was clean only because the repo had zero forks.
