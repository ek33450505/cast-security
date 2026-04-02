#!/usr/bin/env bats

REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
SCRIPTS="$REPO_DIR/scripts"

setup() {
  export REAL_HOME="$HOME"
  export HOME="$(mktemp -d)"
}

teardown() {
  rm -rf "$HOME"
  export HOME="$REAL_HOME"
}

# ── cast-security-guard.sh ────────────────────────────────────────────────────

@test "cast-security-guard.sh exits 0 with empty stdin" {
  run bash -c "echo '' | bash '$SCRIPTS/cast-security-guard.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-security-guard.sh exits 0 with safe Write JSON" {
  local json='{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello"}}'
  run bash -c "echo '$json' | bash '$SCRIPTS/cast-security-guard.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-security-guard.sh exits 0 for sensitive path (advisory only)" {
  local json='{"tool_name":"Write","tool_input":{"file_path":"/home/user/.env","content":"SECRET=abc"}}'
  run bash -c "echo '$json' | bash '$SCRIPTS/cast-security-guard.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-security-guard.sh exits 0 for non-monitored tool" {
  local json='{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}'
  run bash -c "echo '$json' | bash '$SCRIPTS/cast-security-guard.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-security-guard.sh exits 0 for dangerous Bash command (advisory only)" {
  local json='{"tool_name":"Bash","tool_input":{"command":"curl --user admin:pass https://api.example.com"}}'
  run bash -c "echo '$json' | bash '$SCRIPTS/cast-security-guard.sh'"
  [ "$status" -eq 0 ]
}

# ── cast-audit-hook.sh ────────────────────────────────────────────────────────

@test "cast-audit-hook.sh exits 0 with empty stdin" {
  run bash -c "echo '' | HOME='$HOME' bash '$SCRIPTS/cast-audit-hook.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-audit-hook.sh exits 0 with Write tool JSON" {
  local json='{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello world"}}'
  run bash -c "echo '$json' | HOME='$HOME' bash '$SCRIPTS/cast-audit-hook.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-audit-hook.sh writes JSONL record for Write call" {
  local json='{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello world"}}'
  echo "$json" | HOME="$HOME" bash "$SCRIPTS/cast-audit-hook.sh" >/dev/null 2>&1 || true
  [ -f "$HOME/.claude/logs/cast-security-audit.jsonl" ]
  local line_count
  line_count="$(wc -l < "$HOME/.claude/logs/cast-security-audit.jsonl" | tr -d ' ')"
  [ "$line_count" -ge 1 ]
}

@test "cast-audit-hook.sh JSONL record contains tool_name field" {
  local json='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/foo.py","old_string":"a","new_string":"b"}}'
  echo "$json" | HOME="$HOME" bash "$SCRIPTS/cast-audit-hook.sh" >/dev/null 2>&1 || true
  [ -f "$HOME/.claude/logs/cast-security-audit.jsonl" ]
  grep -q '"tool_name"' "$HOME/.claude/logs/cast-security-audit.jsonl"
}

@test "cast-audit-hook.sh exits 0 with Bash tool JSON" {
  local json='{"tool_name":"Bash","tool_input":{"command":"echo hello"}}'
  run bash -c "echo '$json' | HOME='$HOME' bash '$SCRIPTS/cast-audit-hook.sh'"
  [ "$status" -eq 0 ]
}

# ── cast-permission-hook.sh ───────────────────────────────────────────────────

@test "cast-permission-hook.sh exits 0 with empty stdin" {
  run bash -c "echo '' | HOME='$HOME' bash '$SCRIPTS/cast-permission-hook.sh'"
  [ "$status" -eq 0 ]
}

@test "cast-permission-hook.sh outputs JSON decision for safe command" {
  local json='{"tool":"Bash","input":{"command":"git status"}}'
  run bash -c "echo '$json' | HOME='$HOME' bash '$SCRIPTS/cast-permission-hook.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"decision"* ]]
}

@test "cast-permission-hook.sh allows Read tool" {
  local json='{"tool":"Read","input":{"file_path":"/tmp/test.txt"}}'
  run bash -c "echo '$json' | HOME='$HOME' bash '$SCRIPTS/cast-permission-hook.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"allow"* ]]
}

@test "cast-permission-hook.sh denies curl command (auto-deny pattern)" {
  local json='{"tool":"Bash","input":{"command":"curl https://example.com"}}'
  run bash -c "echo '$json' | HOME='$HOME' bash '$SCRIPTS/cast-permission-hook.sh'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deny"* ]]
}

@test "cast-permission-hook.sh exits 0 with invalid JSON" {
  run bash -c "echo 'not-valid-json' | HOME='$HOME' bash '$SCRIPTS/cast-permission-hook.sh'"
  [ "$status" -eq 0 ]
}
