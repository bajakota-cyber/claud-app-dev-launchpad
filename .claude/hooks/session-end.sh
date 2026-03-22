#!/bin/bash
# Stop hook: Runs after every Claude response
# 1. Lightweight Press — records changed files to engineering journal
# 2. Git warning — flags uncommitted work
# 3. Coach-due check — signals if coach needs to run

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
DATE=$(date +"%Y-%m-%d")

cd "$CWD" 2>/dev/null || exit 0

# ── 1. LIGHTWEIGHT PRESS ─────────────────────────────────────────────────────
# Record any file changes to the engineering journal after every response

JOURNAL="$CWD/.claude/engineering-journal.md"
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null)
STAGED_FILES=$(git diff --name-only --cached 2>/dev/null)
ALL_CHANGED=$(echo -e "$CHANGED_FILES\n$STAGED_FILES" | grep -v '^$' | grep -v '\.claude/' | sort -u)

if [ -n "$ALL_CHANGED" ]; then
    FILE_COUNT=$(echo "$ALL_CHANGED" | wc -l | tr -d ' ')
    FILE_LIST=$(echo "$ALL_CHANGED" | head -5 | tr '\n' ', ' | sed 's/,$//')
    if [ "$FILE_COUNT" -gt "5" ]; then
        FILE_LIST="$FILE_LIST ... (+$((FILE_COUNT - 5)) more)"
    fi

    # Only write if journal exists
    if [ -f "$JOURNAL" ]; then
        echo "" >> "$JOURNAL"
        echo "### $TIMESTAMP — $FILE_COUNT file(s) changed" >> "$JOURNAL"
        echo "Files: $FILE_LIST" >> "$JOURNAL"
    fi
fi

# ── 2. GIT WARNING ───────────────────────────────────────────────────────────
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    UNCOMMITTED=$(git status --short 2>/dev/null | grep -v "^??" | wc -l | tr -d ' ')
    UNTRACKED=$(git status --short 2>/dev/null | grep "^??" | grep -v "\.claude/" | wc -l | tr -d ' ')

    if [ "$UNCOMMITTED" -gt "0" ] || [ "$UNTRACKED" -gt "0" ]; then
        echo "" >&2
        echo "⚠️  UNSAVED WORK: $UNCOMMITTED modified, $UNTRACKED untracked. Say 'commit my work' to save." >&2
    fi
fi

# ── 3. COACH-DUE CHECK ───────────────────────────────────────────────────────
COACH_DUE="$CWD/.claude/.coach-due"
if [ -f "$COACH_DUE" ]; then
    DUE_DATE=$(cat "$COACH_DUE")
    echo "" >&2
    echo "📋 COACH IS DUE (scheduled since $DUE_DATE). Invoke coach to run the team review." >&2
fi

# Write session marker
echo "$TIMESTAMP" > "$CWD/.claude/.last-session" 2>/dev/null

exit 0
