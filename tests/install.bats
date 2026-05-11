#!/usr/bin/env bats

REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  export REAL_HOME="$HOME"
  export HOME="$(mktemp -d)"
  export PATH="$REPO_DIR/bin:$PATH"
}

teardown() {
  rm -rf "$HOME"
  export HOME="$REAL_HOME"
}

@test "install.sh exits 0" {
  run bash "$REPO_DIR/install.sh"
  [ $status -eq 0 ]
}

@test "install is idempotent" {
  run bash "$REPO_DIR/install.sh"
  [ $status -eq 0 ]
  run bash "$REPO_DIR/install.sh"
  [ $status -eq 0 ]
}

@test "cast-security-guard.sh is installed" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -f "$HOME/.claude/scripts/cast-security-guard.sh" ]
}

@test "cast-permission-hook.sh is installed" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -f "$HOME/.claude/scripts/cast-permission-hook.sh" ]
}

@test "cast-audit-hook.sh is installed" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -f "$HOME/.claude/scripts/cast-audit-hook.sh" ]
}

@test "cast-redact.py is installed" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -f "$HOME/.claude/scripts/cast-redact.py" ]
}

@test "pii-patterns.json is installed" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -f "$HOME/.claude/config/pii-patterns.json" ]
}

@test "scripts are executable after install" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -x "$HOME/.claude/scripts/cast-security-guard.sh" ]
  [ -x "$HOME/.claude/scripts/cast-permission-hook.sh" ]
  [ -x "$HOME/.claude/scripts/cast-audit-hook.sh" ]
}

@test "cast-security directory is created" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  [ -d "$HOME/.claude/cast-security" ]
}

@test "cast-security --version works after install" {
  bash "$REPO_DIR/install.sh" >/dev/null 2>&1
  run cast-security --version
  [ $status -eq 0 ]
  [[ "$output" == *"0.3.0"* ]]
}
