#!/usr/bin/env bats

REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup_file() {
  export SHARED_HOME="$(mktemp -d)"
  HOME="$SHARED_HOME" bash "$REPO_DIR/install.sh" >/dev/null 2>&1
}

teardown_file() {
  rm -rf "$SHARED_HOME"
}

setup() {
  export HOME="$SHARED_HOME"
  export PATH="$REPO_DIR/bin:$PATH"
}

@test "--version exits 0 and shows 0.3.1" {
  run cast-security --version
  [ $status -eq 0 ]
  [[ "$output" == *"0.3.1"* ]]
}

@test "--help exits 0" {
  run cast-security --help
  [ $status -eq 0 ]
}

@test "status exits 0" {
  run cast-security status
  [ $status -eq 0 ]
}

@test "policies exits 0 when policies.json exists" {
  run cast-security policies
  [ $status -eq 0 ]
}

@test "audit --tail 5 exits 0 (empty log)" {
  run cast-security audit --tail 5
  [ $status -eq 0 ]
}

@test "redact exits 0 on safe text" {
  run cast-security redact "hello world"
  [ $status -eq 0 ]
}

@test "redact exits 0 on text with email" {
  run cast-security redact "my email is test@example.com"
  [ $status -eq 0 ]
}

@test "unknown subcommand exits non-zero" {
  run cast-security bogus-subcommand
  [ $status -ne 0 ]
}
