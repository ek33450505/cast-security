# Changelog

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
