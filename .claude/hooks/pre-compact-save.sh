#!/bin/bash
# PreCompact hook: Saves a snapshot of the current state before conversation compaction
# This is your safety net against losing critical context

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Create the compaction snapshot directory
SNAPSHOT_DIR="$CWD/.claude/compaction-snapshots"
mkdir -p "$SNAPSHOT_DIR"

# Capture current state
SNAPSHOT_FILE="$SNAPSHOT_DIR/snapshot-$(date +%Y%m%d-%H%M%S).md"

{
    echo "# Pre-Compaction Snapshot"
    echo "**Saved**: $TIMESTAMP"
    echo "**Session**: $SESSION_ID"
    echo ""
    echo "## Recent Git Activity"
    cd "$CWD" 2>/dev/null
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo '```'
        git log --oneline -10 2>/dev/null || echo "(no commits yet)"
        echo '```'
        echo ""
        echo "## Uncommitted Changes"
        echo '```'
        git diff --stat 2>/dev/null || echo "(no changes)"
        echo '```'
        echo ""
        echo "## Untracked Files"
        echo '```'
        git status --short 2>/dev/null | head -20
        echo '```'
    else
        echo "(not a git repo)"
    fi
    echo ""
    echo "## Project Structure (top 2 levels)"
    echo '```'
    find "$CWD" -maxdepth 2 -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/.next/*' -not -path '*/__pycache__/*' 2>/dev/null | head -50
    echo '```'
} > "$SNAPSHOT_FILE" 2>/dev/null

# Keep only last 5 snapshots to avoid bloat
ls -t "$SNAPSHOT_DIR"/snapshot-*.md 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

# Append session end marker to engineering journal
JOURNAL_FILE="$CWD/.claude/engineering-journal.md"
if [ -f "$JOURNAL_FILE" ]; then
    echo "" >> "$JOURNAL_FILE"
    echo "*(session compacted: $TIMESTAMP)*" >> "$JOURNAL_FILE"
    echo "" >> "$JOURNAL_FILE"
fi

# Output a message that Claude will see
echo "Pre-compaction snapshot saved to $SNAPSHOT_FILE" >&2
exit 0
