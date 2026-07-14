#!/bin/bash
# 全域 UserPromptSubmit hook:Claude Code 會把事件 JSON 從 stdin 餵進來,
# 這裡取出 prompt 附加到 ~/.claude/prompt-log/YYYY-MM-DD.jsonl(一行一筆)。
# 記錄 cwd,方便之後按專案過濾。
log_dir="$HOME/.claude/prompt-log"
mkdir -p "$log_dir"
jq -c '{time: (now | strflocaltime("%Y-%m-%dT%H:%M:%S")), session: .session_id, cwd: .cwd, prompt: .prompt}' \
  >> "$log_dir/$(date +%Y-%m-%d).jsonl"
