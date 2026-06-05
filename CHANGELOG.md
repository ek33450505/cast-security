# Changelog

## [v0.3.0] — 2026-06-05 — Ecosystem audit + security correctness backports

### Doc fixes
- README: corrected cast-hooks count (13 → 20) in the ecosystem table
- README: removed fabricated "Constellation 3D graph" claim from cast-desktop description
- SECURITY.md: updated supported version range from 0.1.x to 0.3.x
- Formula/cast-security.rb: switched URL from rolling `main.tar.gz` to versioned tag archive; bumped version from 0.1.0 to 0.3.0

### Code backports from flagship (claude-agent-team v7.4.1)
- `scripts/pre-tool-guard.sh`: added git global-option tolerance to git commit/push blocks so `git -C <dir>` no longer bypasses the guard; added git-stash block (`CAST_STASH_OK=1` escape hatch) per the 2026-05-19 stash incident
- `scripts/cast-redact.py`: added 3 missing PII patterns (ABSOLUTE_PATH, BITBUCKET_URL, SLACK_WEBHOOK); added precompiled-regex cache (_COMPILED_PATTERNS) and fast short-circuit (_PII_CANDIDATES) to avoid per-call re.compile overhead
- `settings.json`: added `WebFetch|WebSearch` to the cast-audit matcher so PII detection fires on cloud-bound calls (this was the missing link behind the README headline "PII redaction on WebFetch/WebSearch")
- `scripts/cast-permission-hook.sh`: removed fabricated ANTI_DISTILLATION_CC comment (fictional feature flag)

## [0.3.0] — 2026-05-11 — CAST v7 Sync

### Added
- `scripts/cast-audit.py` — consolidated audit parsing, PII analysis,
  and record-writing in Python. `cast-audit-hook.sh` now delegates
  to this script (reduces inline Python from ~300 to ~60 lines).

### Changed
- `pre-tool-guard.sh`:
  - Gained TTL sweep for stale agent-status files
  - Added `CLAUDE_SUBPROCESS=1` escape-hatch path (subagent commits
    no longer incorrectly blocked in standalone use)
- `cast-audit-hook.sh`: refactored to delegate to `cast-audit.py`.

### Preserved
- Audit log path remains `cast-security-audit.jsonl` (cast-security's
  documented differentiation from canonical CAST `audit.jsonl`).

### Tests
- BATS: 33/33 pass.

## [0.2.0] — 2026-04-03

### Added

- `pre-tool-guard.sh` — PreToolUse Bash guard that blocks destructive git operations (force-push to main/master, reset --hard, checkout ., clean -f)
- `cast-headless-guard.sh` — PreToolUse guard that blocks `AskUserQuestion` tool calls in headless/cron sessions where no human is present to respond

### Changed

- `cast-audit-hook.sh` — synced with CAST v4.2: audit log path changed to `~/.claude/logs/audit.jsonl`, PII enforcement now reads `redact_pii` flag from `cast-cli.json` (replaces `CAST_PII_ENFORCEMENT` env var), added safelist pattern checking before blocking
- `cast-permission-hook.sh` — synced with CAST v4.2: rules and timestamp paths updated to `~/.claude/cast/` directory
- `cast-redact.py` — synced with CAST v4.2: includes PII safelist fixes
- `pii-patterns.json` — synced with CAST v4.2 upstream
- `policies.json` — synced with CAST v4.2 upstream
- `settings.json` — updated to v4 format: all hook entries now include `id`, `matcher`, and `timeout` fields; added entries for `pre-tool-guard.sh` and `cast-headless-guard.sh`

## [0.1.0] — 2026-04-02

### Added
- `cast-security-guard.sh` — PreToolUse advisory scanner for sensitive file paths and dangerous commands
- `cast-permission-hook.sh` — PermissionRequest auto-deny for sensitive system paths, with configurable rules via `permission-rules.json`
- `cast-audit-hook.sh` — SHA256 audit trail for all Write/Edit tool calls, appends JSONL to `~/.claude/logs/cast-security-audit.jsonl`
- `cast-redact.py` — PII detection and redaction engine with configurable regex patterns; supports Microsoft Presidio with pure-regex fallback
- `cast-security` CLI — `status`, `audit`, `redact`, `policies`, `install` subcommands
- `pii-patterns.json` — 17 built-in PII pattern recognizers (API keys, JWTs, database URLs, cloud credentials, etc.)
- `policies.json` — Example path-based write governance policies
- `install.sh` — Non-destructive installer: copies scripts, merges `settings.json` hooks, symlinks CLI
- `settings.json` — Pre-wired hook configuration for all three hooks
- Homebrew formula via `ek33450505/cast-security` tap
- BATS test suite: `install.bats`, `cli.bats`, `hooks.bats`
- GitHub Actions CI: matrix (ubuntu-latest, macos-latest), daily schedule
