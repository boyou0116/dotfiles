#!/bin/bash
# Global UserPromptSubmit hook: Claude Code feeds the event JSON via stdin;
# extract the prompt and append it to ~/.claude/prompt-log/YYYY-MM-DD.jsonl
# (one entry per line). Records cwd so entries can be filtered by project later.
log_dir="$HOME/.claude/prompt-log"
mkdir -p "$log_dir"
jq -c '{time: (now | strflocaltime("%Y-%m-%dT%H:%M:%S")), session: .session_id, cwd: .cwd, prompt: .prompt}' \
  >> "$log_dir/$(date +%Y-%m-%d).jsonl"
