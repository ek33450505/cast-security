# Changelog

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
