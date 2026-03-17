#!/bin/bash
# PostToolUse hook: Checks files written/edited for obvious security issues
# This runs after Edit or Write operations and warns about potential secrets

# Read the tool input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Skip non-code files
case "$FILE_PATH" in
    *.png|*.jpg|*.gif|*.ico|*.svg|*.woff|*.ttf|*.lock|*.map)
        exit 0
        ;;
esac

# Check for potential hardcoded secrets
ISSUES=""

# API keys and tokens (common patterns)
if grep -nP '(api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token|private[_-]?key)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{10,}' "$FILE_PATH" 2>/dev/null | grep -v '\.env\.example' | grep -v 'process\.env' | grep -v 'os\.environ' | head -5; then
    ISSUES="$ISSUES\n- Possible hardcoded API key or secret found"
fi

# Known API key prefixes
if grep -nP '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{82}|xoxb-[0-9-]+|xoxp-[0-9-]+|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35})' "$FILE_PATH" 2>/dev/null | head -5; then
    ISSUES="$ISSUES\n- Known API key pattern detected (OpenAI/GitHub/Slack/AWS/Google)"
fi

# Private keys
if grep -n 'BEGIN.*PRIVATE KEY' "$FILE_PATH" 2>/dev/null | head -3; then
    ISSUES="$ISSUES\n- Private key found in source file"
fi

# Password assignments (not in .env files)
if echo "$FILE_PATH" | grep -qvP '\.env'; then
    if grep -nP 'password\s*[:=]\s*["\x27][^"\x27]{3,}["\x27]' "$FILE_PATH" 2>/dev/null | grep -v 'placeholder' | grep -v 'example' | grep -v 'test' | grep -v 'TODO' | head -3; then
        ISSUES="$ISSUES\n- Possible hardcoded password"
    fi
fi

if [ -n "$ISSUES" ]; then
    echo -e "SECURITY WARNING in $FILE_PATH:$ISSUES" >&2
    echo -e "\nConsider moving secrets to environment variables (.env file) and using process.env or os.environ to access them." >&2
    # Exit 0 (don't block) but the warning goes to stderr which Claude sees
    exit 0
fi

exit 0
