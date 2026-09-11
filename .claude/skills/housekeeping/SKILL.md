---
name: housekeeping
description: Find and reconcile branch/fork divergence and keep every copy of the code in sync — GitHub, the local working directory, and wherever the code is actually deployed (a VM, a server). Run at EOD and whenever branches may have drifted. Consolidates stray branches back to the trunk WITHOUT losing work, and reconciles the three copies so they match.
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent, TodoWrite
argument-hint: "[optional: repo path, or a note]"
---

# Housekeeping — reconcile branches, keep every copy in sync

## Why this exists (read this first)

The operator is a non-developer. **They do not know when a branch, fork, or split
was created** — often the assistant made one and moved on, and the operator was
never aware. So diverged branches and out-of-sync copies accumulate SILENTLY and
never get resolved, because nobody knows to ask. A branch full of real work can sit
orphaned for weeks; the deployed app can drift versions behind the code ("I fixed
that already but I don't see it"). This skill's job is to find that drift the
operator can't see, reconcile it safely, and report it in plain terms.

There are usually THREE copies of any codebase, and they drift independently:
1. **GitHub** (the online backup / source of truth for sharing)
2. **The local working directory** (where edits happen)
3. **The deployment target** — the VM/server/box where the code actually RUNS and
   the operator actually looks at it. This one is separate from git entirely
   (getting code here is a *deploy*, not a commit/push).

The end state we want, per repo: **GitHub = local working dir = deployment target,
all on one trunk, with no work lost.**

## Cardinal rules — never violate these

1. **Verify before you overwrite or delete.** Always establish which side is the
   source of truth FIRST (content, line counts, mtimes, commit dates). A blind
   push/deploy/merge that clobbers newer work is the primary danger. (A real
   near-miss: a deploy would have overwritten a file the VM had 70+ newer lines in.)
2. **Pull before you push.** Fetch and review the other side before writing over it.
3. **Never delete a branch until its unique work is provably preserved** — in the
   trunk's history, in an `archive/<name>-<date>` tag (pushed), or in another repo.
   Tag first, delete second.
4. **Destructive steps need explicit operator approval.** Branch deletion (local
   OR remote), force-push, history rewrite, and changing the default branch are
   DRAFTED and presented — never auto-executed. Discovery is proactive; destruction
   is conservative.
5. **Respect intentional branches.** A deliberate experiment, a feature-in-progress,
   or a branch the operator says is on purpose is NOT garbage. Do not force-merge or
   delete it. When you cannot tell intentional-from-abandoned, ASK — and explain in
   plain terms what the branch is and what's on it, because the operator likely does
   not know it exists.
6. **The deployment target can be AHEAD of the repo.** Work is sometimes done
   directly on the box. Treat the VM/server as a possible SOURCE of stranded work,
   not just a destination. And when you compare repo-to-deploy, **walk the whole
   tree** — never trust a check that only compares files it already lists, because it
   is structurally blind to newly-added files (this is exactly how 36 files once hid
   unnoticed on a VM while the check reported "0 differ").

## Procedure

### 1. Map the landscape (per repo)
- `git branch -a`, `git remote -v`; identify the **trunk** (the default branch —
  confirm with `git remote show origin` / `gh repo view`, don't assume it's `main`
  or `master`; it may be an oddly-named line).
- Identify the **deployment target(s)**: where does this code actually run? (a VM
  dir, a server path, a container). Check the repo's deploy tooling / launch config.
- Note any **sibling repos** — a project may have split into several (e.g. an app and
  a spun-off sub-project); work can be stranded across the split.
- For each branch: ahead/behind the trunk (`git rev-list --count trunk..branch` and
  the reverse), last commit date, and local-vs-origin sync.

### 2. Classify each non-trunk branch
Compute each branch's UNIQUE contribution with a three-dot diff (`git diff --name-only
trunk...branch`) and `git rev-list --count trunk..branch`:
- **Contained / merged** (0 unique commits): safe to retire.
- **Superseded** (unique commits, but the same outcome is ALREADY in the trunk by
  content — the change was redone another way): confirm by content, then safe to
  retire. (Verify — don't assume; grep the trunk for the thing the branch changed.)
- **Stranded work** (real unique commits, not in trunk, not done elsewhere): must be
  merged/rescued BEFORE any cleanup.
- **Belongs in another repo** (its unique work is a different product): rescue it INTO
  that repo — and first CHECK whether it's already there and complete, because
  splitting from the wrong branch silently strands work. Archive-tag it, then it can
  leave this repo.
- **Intentional** (deliberate, recent, purposeful, or operator-confirmed): LEAVE IT.
  Flag it in the report; do not consolidate.

### 3. Reconcile — additive first, destructive last (and only with approval)
- Rescue/merge stranded work into the trunk (or the correct repo), **pull-first**, and
  verify the merge did not silently drop anything (diff the result against both sides).
- Before deleting ANY branch that has unique history: `git tag archive/<name>-<date>
  <branch>` and push the tag. The commits survive even after the branch is gone.
- **Present the destructive cleanup for approval**: list every branch to delete and,
  next to each, exactly where its work now lives (trunk history / archive tag / other
  repo). Delete (local and remote) only on an explicit yes. If a delete is blocked by
  a safety guard, that is correct — surface it, don't force around it.

### 4. Verify the three copies match
Per repo, drive toward **GitHub = local = deployment target** on the trunk:
- **Local ↔ GitHub**: on the trunk, `git status` clean, `git rev-list --count
  origin/trunk..trunk` and reverse both 0.
- **Local ↔ deployment target**: a **full-tree** comparison (hash/`diff` every source
  file both directions), not a hand-maintained manifest. Report files present on one
  side and missing on the other, in BOTH directions.
- Fix drift in the CORRECT direction: decide which side is newer/authoritative before
  overwriting. If the deploy target is ahead, pull it back into the repo first; if the
  repo is ahead, deploy. Never blind-overwrite either way.

### 5. Report (plain language — the operator is not a coder)
- Every branch found, and for each: **kept** (why — intentional/trunk) or **retired**
  (and where its work went).
- Any work rescued, from where, to where.
- Whether GitHub = local = deployment target now, per repo — say it plainly.
- Anything still needing the operator's decision (intentional-vs-abandoned calls,
  approvals for deletes).
Assume the operator did not know these branches existed; explain what you found.

## When to run
- **Every EOD** (the `eod` skill invokes this; coach also runs it).
- Whenever branch/fork divergence is noticed, or before/after big multi-branch work.
- Whenever the deployed app and the code seem out of sync ("I fixed that already but
  I don't see it") — that symptom is almost always a deploy that never happened or a
  branch that never merged.
