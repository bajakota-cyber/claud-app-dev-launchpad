#!/bin/bash
# Stop hook: Runs when Claude finishes a response
# Checks for uncommitted changes and warns the user

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

cd "$CWD" 2>/dev/null || exit 0

# Only run in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Check for uncommitted changes
UNCOMMITTED=$(git status --short 2>/dev/null | grep -v "^??" | wc -l | tr -d ' ')
UNTRACKED=$(git status --short 2>/dev/null | grep "^??" | grep -v ".claude/" | wc -l | tr -d ' ')

if [ "$UNCOMMITTED" -gt "0" ] || [ "$UNTRACKED" -gt "0" ]; then
    echo "" >&2
    echo "⚠️  UNSAVED WORK DETECTED" >&2
    echo "   $UNCOMMITTED modified/staged file(s), $UNTRACKED untracked file(s)" >&2
    echo "   Say 'commit my work' to save before ending the session." >&2
    echo "" >&2
fi

# Write session marker for next-session startup awareness
MARKER_FILE="$CWD/.claude/.last-session"
echo "$TIMESTAMP" > "$MARKER_FILE" 2>/dev/null

exit 0
