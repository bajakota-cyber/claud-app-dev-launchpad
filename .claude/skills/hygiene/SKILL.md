---
name: hygiene
description: This skill should be used when the user asks to "clean up the code", "run hygiene", "do a code review", "check code quality", "look for dead code", "find orphaned code", "find unused functions", "refactor", "clean well formatted functions", or wants to improve general code health. Audits the codebase for common AI-generated code quality problems and fixes them.
version: 1.0.0
---

# Code Hygiene Audit

When this skill activates, perform a **full audit** of the codebase and fix every issue found. Do not just report — fix.

---

## Phase 1 — Find Everything First

Before touching a single line, scan the entire codebase and build a complete list of issues. Read the actual files. Check all of: `views/`, `services/`, `repositories/`, `components/`, `models/`.

---

## What to Look For

### 🔴 Dead / Orphaned Code
- Functions defined but never called anywhere in the codebase
- Classes or methods that are imported but never used
- Entire code blocks that can never be reached (after `return`, after `raise`, unreachable `else`)
- Old feature code that was superseded but never deleted
- **How to check:** Grep every function name across all files. If zero hits outside its own definition, it's dead.

### 🔴 Unused Imports
- `import X` at the top of a file where `X` is never referenced in that file
- `from X import Y` where `Y` is never used
- Aliased imports (`import X as _x`) where `_x` never appears
- **How to check:** For each import, grep the file for the imported name.

### 🟠 Debug Statements Left In
- `print(...)` calls that were added for debugging and never removed
- `print(f"[DEBUG] ...")`, `print("HERE")`, `print(variable)` scattered through production code
- **Exception:** Intentional operational logs with a consistent prefix (e.g. `[ASSESSOR]` status messages) are acceptable — use judgment.

### 🟠 Commented-Out Code
- Large blocks of code that are commented out instead of deleted
- `# old version:` blocks, `# TODO: remove this` blocks with code still present
- **Exception:** Short single-line comments explaining *why* something was disabled are fine.

### 🟠 Broad / Redundant Exception Handlers
- `except Exception: pass` — swallows all errors silently
- `except (ValueError, Exception):` — redundant since `Exception` is parent of `ValueError`; simplify to `except Exception:`
- `except Exception as e: return ""` — silently eating errors in ways that hide bugs
- **Fix:** Either narrow the exception type, log it, or re-raise. Never silently discard.

### 🟡 Redundant / Verbose Patterns
- `if x == True:` → `if x:`
- `if x == False:` → `if not x:`
- `if x is not None: return x else: return None` → `return x`
- `.filter(Model.flag == True)` → `.filter(Model.flag)` (SQLAlchemy ORM)
- `return True` at end of function that always returns True — might not need a return value
- Double negatives: `if not x == y` → `if x != y`

### 🟡 Magic Numbers and Hardcoded Strings
- Numeric literals used more than once with no explanation (`1.2`, `30`, `8765`, `3600`)
- The same string literal repeated in multiple places that should be a constant
- **Fix:** Extract to a module-level constant with a descriptive name.

### 🟠 DRY Violations (Don't Repeat Yourself)

AI generates code incrementally across sessions with no memory of what it wrote earlier. When a new feature needs logic that already exists elsewhere, the AI re-implements it instead of reusing it — because it either didn't search or didn't find the original. The result is two (or more) implementations growing in parallel, silently drifting apart. The tell-tale sign: a bug fix or new field applied to one copy is missing from the other.

**Six specific patterns to hunt for:**

**1. Duplicated inline imports** — the same `from X import Y` statement appearing inside multiple functions in the same file. A single module-level import serves all of them.
```python
# Bad: appears inside 4 separate functions in the same file
def _render_note_row(...):
    from repositories import document_repo   # ← repeated
    ...
def _add_line_item(...):
    from repositories import document_repo   # ← repeated again
```
- **How to check:** Grep each file for `from X import` inside function bodies. If the same module is imported more than once, move it to the top of the file.

**2. Aliased re-imports** — importing the same module under a different alias (`as _jr`, `as _ss2`, `as _sr3`) because the author forgot the module was already imported or invented a fake name-conflict. Every alias is a hidden duplicate.
```python
# Bad: job_repo is already at module level but re-imported 3× under aliases
from repositories import job_repo as _jr        # ← alias #1
from services import settings_service as _ss2   # ← alias #2
from repositories import settings_repo as _sr   # ← alias #3
```
- **Fix:** Remove the aliased import, use the canonical module-level name throughout.

**3. Duplicated UI form widget trees** — two separate files that render the same logical form (same field labels, same data shape) independently. Any new field added to one is silently missing from the other.
```
# Bad: new_job.py renders "Customer Type / First Name / Last Name / Billing Address / Phone / Email"
# customers.py renders the exact same 6 fields independently
# → Adding "Secondary Phone" to one does not add it to the other
```
- **How to check:** Search for widget label strings (e.g. `"Billing Address"`, `"Main Phone"`) across all view files. If the same label appears in more than one file with a similar surrounding structure, there's a duplicated form.
- **Fix:** Extract a shared `render_X_form(key, record, db)` function in the primary file, called by both views.

**4. Duplicated raw ORM queries** — the same `db.query(Model).filter(...).order_by(...)` block copy-pasted across multiple views instead of living once in a repository function.
```python
# Bad: identical query in new_job.py AND job_package.py
active_types = (
    db.query(JobType)
    .filter(JobType.is_active)
    .order_by(JobType.sort_order, JobType.name)
    .all()
)
```
- **How to check:** Search view files for `db.query(` — any ORM query in a view is a candidate. If the same model appears in multiple views, check if the query is identical.
- **Fix:** Add a `get_active_X(db)` function to the relevant repository and call it from both views.

**5. Duplicated constructor kwargs** — repeated model instantiation blocks where 6+ fields are copy-pasted across multiple functions, differing only in the parent ID field.
```python
# Bad: same 8 snapshot fields copied into 3 separate copy functions
WorkOrderLineItem(work_order_id=wo.id, sort_order=i, base_id=item.base_id,
    type_id=item.type_id, where_id=item.where_id,
    base_name_snapshot=item.base_name_snapshot, ...)  # ← repeated in 3 functions
```
- **Fix:** Extract a `_field_snapshot(item) -> dict` helper and use `**_field_snapshot(item)` in each constructor. The copy functions shrink to 3 lines each.

**6. Utility functions living in the wrong module** — pure calculation or formatting functions defined in one module (e.g. a view file) and imported by other views directly from that module, creating hidden cross-view coupling. If the "source" module is ever deleted or refactored, all importers silently break.
```python
# Bad: new_job.py and job_package.py both import calculation functions from document_editor.py
from views.document_editor import _fetch_drive_time, _parse_appt_time, _safe_float
# ↑ two views now depend on a third view for unrelated logic
```
- **How to check:** Look for `from views.X import` statements in other view files. Views should not import from each other for utility functions.
- **Fix:** Move shared utilities to a dedicated `utils/` module (e.g. `utils/appointment.py`, `utils/convert.py`). All views import from `utils`, not from each other.

### 🟡 Inconsistent Patterns Within the Same File
- Mixed import styles: `import X` in some places, `from X import Y` in others for the same module
- Inconsistent string formatting: f-strings vs `.format()` vs `%` in the same file
- Inconsistent naming: `myVar` vs `my_var` mixed in the same file

### 🟢 Stale / Misleading Comments
- Comments that describe what the code *used to* do, not what it does now
- Comments that repeat the code literally (`# increment x` above `x += 1`)
- TODO/FIXME/HACK comments that are years old and reference resolved issues
- Docstrings that list wrong parameter names or return types

### 🟢 Function Length / Single Responsibility
- Functions over ~80 lines that are doing multiple distinct things
- **Look for natural seams** — if a function has clear sections (e.g. `# Step 1`, `# Step 2`), each section may belong in its own helper
- **Don't split mechanically** — only split if the pieces have clear names and don't need excessive parameter passing

### 🟢 Missing Guards / Early Returns
- Functions that do 50 lines of work then check if input was valid at the bottom
- **Fix:** Add guard clauses at the top (`if not x: return`)

---

## AI-Specific Patterns to Watch For

These are patterns that appear frequently in AI-generated code:

| Pattern | Description |
|---|---|
| **DRY drift** | Two implementations of the same form, query, or utility start identical and slowly diverge as one is updated and the other isn't. Classic sign: a bug fix applied in one place resurfaces in another. Search for repeated widget labels, identical `db.query(...)` blocks, and `from views.X import` in other views. |
| **Context drift** | A function was written in session 1, then quietly rewritten in session 5 with slightly different behavior. Look for duplicate function names or two functions doing the same job. |
| **Hallucinated method calls** | Calls to methods that don't exist on the object (e.g., `db.save()` when the ORM uses `db.flush()`). These cause `AttributeError` at runtime. |
| **Session state key proliferation** | Dozens of one-off session state keys with inconsistent naming. Audit them: are they all still read? Are any set but never consumed? |
| **Over-engineered one-offs** | A complex class or abstraction built for a single use case that was never reused. Simplify to a function. |
| **Defensive code that never fires** | `if db is None: return` when `db` is never None in practice. Remove dead guards. |
| **N+1 queries in loops** | `for item in items: db.query(Model).filter(...).first()` — should be a single query with `in_()`. |
| **Inconsistent return types** | A function that returns `str` in one branch, `None` in another, and `int` in a third. |

---

## Phase 2 — Fix Everything Found

After the audit:

1. **Delete** dead functions, unused imports, commented-out code blocks
2. **Simplify** redundant patterns in-place
3. **Extract constants** for magic numbers (module-level, UPPER_CASE)
4. **Narrow exception handlers** or at minimum add a `print`/`log` call so errors aren't invisible
5. **Extract helpers** for any duplicated logic
6. **Clean up stale comments** — update or delete them

---

## Phase 3 — Verify Nothing Broke

After all changes:
- Re-read each modified file top to bottom
- Confirm no function calls reference a name that was deleted
- Confirm all imports are still valid
- If the project has tests, note which test files exist so the user can run them

---

## Reporting

After cleanup, give the user a **summary table**:

| File | Issue | Action Taken |
|---|---|---|
| `services/foo.py` | Unused import `os` | Deleted |
| `views/bar.py` | `except (ValueError, Exception)` × 3 | Simplified to `except Exception` |
| `views/bar.py` | `== True` comparisons × 5 | Simplified to boolean expressions |
| `services/baz.py` | Magic number `1.2` (drive buffer) | Extracted to `_DRIVE_BUFFER = 1.2` |

Then state: **"No dead functions or orphaned code found"** or list what was removed.
