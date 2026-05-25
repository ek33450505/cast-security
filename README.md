# cast-security

Security hooks and audit trail for Claude Code, with no framework required.

[![CI](https://github.com/ek33450505/cast-security/actions/workflows/ci.yml/badge.svg)](https://github.com/ek33450505/cast-security/actions/workflows/ci.yml)
![version](https://img.shields.io/badge/version-0.3.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)

## What it does

Five-layer security for Claude Code, installable in under 30 seconds:

### Advisory scanner (`cast-security-guard.sh`)
- Fires on every `Write`, `Edit`, and `Bash` tool call via `PreToolUse`
- Pattern-matches sensitive file paths (`.env`, `credentials`, `auth.*`, `api_key`, etc.) and dangerous commands (`curl` with auth headers, `ssh`, `scp`)
- Always exits 0 — advisory only, never hard-blocks Claude Code
- Injects a `[CAST-SECURITY]` warning into the session context when a match is found

### Permission blocker (`cast-permission-hook.sh`)
- Fires on every `PermissionRequest` event
- Auto-denies sensitive system paths: `/etc`, `~/.ssh`, `~/.gnupg`, `~/.aws`, and any paths configured in `policies.json`
- Auto-approves safe read-only git and filesystem commands
- Fully configurable via `~/.claude/cast-security/permission-rules.json`

### Audit trail (`cast-audit-hook.sh`)
- SHA256 fingerprints every `Write` and `Edit` call — content is hashed, never stored raw
- Records timestamp, session ID, project, tool name, file path, and command preview
- Appends one JSONL line per tool call to `~/.claude/logs/cast-security-audit.jsonl`
- Cloud-bound tool calls (`WebFetch`, `WebSearch`) trigger PII detection via `cast-redact.py`

### PII redaction engine (`cast-redact.py`)
- Configurable regex pattern set in `~/.claude/config/pii-patterns.json`
- Detects: email addresses, phone numbers, SSNs, API keys (AWS, GitHub, Anthropic, OpenAI, Stripe, Slack), JWTs, database URLs, PEM private keys, and more
- Two modes: advisory (log only) and strict (block cloud-bound calls with PII)
- Falls back to pure-regex detection when Microsoft Presidio is not installed

## Install

### Homebrew

```bash
brew tap ek33450505/cast-security
brew install cast-security
cast-security install
```

### Manual

```bash
git clone https://github.com/ek33450505/cast-security.git
cd cast-security
bash install.sh
```

## Usage

```
$ cast-security status

cast-security v0.3.0 — Status
════════════════════════════════════
Hook health:
  cast-security-guard.sh          last fired: 2026-04-02 14:01:22
  cast-audit-hook.sh               last fired: 2026-04-02 14:01:22
  cast-permission-hook.sh          last fired: 2026-04-02 13:58:44

Audit log:
  ~/.claude/logs/cast-security-audit.jsonl (142 lines, 48K)

Policies:
  4 active policies in ~/.claude/config/policies.json
```

```bash
# Tail the audit log
cast-security audit
cast-security audit --tail 50

# Run PII detection on any text
cast-security redact "Contact john@example.com or use key sk-ant-abc123..."

# List active write governance policies
cast-security policies

# Run post-install setup (or re-run to merge new hooks)
cast-security install
```

### Git guard (`pre-tool-guard.sh`)
- Fires on every `Bash` tool call via `PreToolUse`
- Blocks destructive git operations: `force-push` to `main`/`master`, `reset --hard`, `checkout .`, `clean -f`, `branch -D`
- Exits 2 (blocks the call) with a descriptive message when a dangerous operation is detected
- No config required — safe defaults out of the box

### Headless guard (`cast-headless-guard.sh`)
- Fires on every `AskUserQuestion` tool call via `PreToolUse`
- Blocks agent prompts for human input in headless/cron sessions where no user is present to respond
- Detects headless mode via `CAST_HEADLESS`, `CI`, and `TERM=dumb` environment variables
- Prevents sessions from hanging indefinitely waiting for a response that will never come

## Hook coverage

| Event | Script | What it does |
|---|---|---|
| `PreToolUse` | `cast-security-guard.sh` | Advisory scan for sensitive paths and commands |
| `PreToolUse` | `cast-audit-hook.sh` | SHA256 audit trail for all tool calls |
| `PreToolUse` | `pre-tool-guard.sh` | Block destructive git operations |
| `PreToolUse` | `cast-headless-guard.sh` | Block `AskUserQuestion` in headless/cron sessions |
| `PermissionRequest` | `cast-permission-hook.sh` | Auto-deny/approve based on configured rules |

## Configuration

### `~/.claude/config/pii-patterns.json`
Custom regex patterns for PII detection. Adds to the built-in pattern set. Format:
```json
{
  "patterns": [
    {
      "name": "MY_INTERNAL_ID",
      "entity_type": "INTERNAL_ID",
      "regex": "EMP-[0-9]{6}",
      "score": 0.9
    }
  ]
}
```

### `~/.claude/config/policies.json`
Path-based write governance rules. Each policy controls which paths require agent review before modification:
```json
{
  "policies": [
    {
      "id": "auth-requires-security",
      "path_pattern": "src/auth/.*",
      "requires_agent": "security",
      "severity": "block"
    }
  ]
}
```

### Strict PII mode
By default, PII detection is advisory — it logs a warning but does not block the tool call. To enable hard-blocking on cloud-bound calls that contain PII, set `redact_pii: true` in `~/.claude/config/cast-cli.json`:

```json
{
  "redact_pii": true
}
```

When strict mode is active, `WebFetch` and `WebSearch` calls containing detected PII will be blocked with exit code 2 and a `[CAST-PII-BLOCK]` message.

## Works with CAST

If you are a [CAST](https://github.com/ek33450505/claude-agent-team) user, these hooks are already wired by the CAST installer. This repo is for standalone Claude Code users who want the security layer without the full CAST framework.

## CAST Ecosystem

> Auto-synced from [claude-agent-team/docs/ecosystem.md](https://github.com/ek33450505/claude-agent-team/blob/main/docs/ecosystem.md). Run `~/Projects/personal/claude-agent-team/scripts/sync-ecosystem-readme.sh` to refresh.

<!-- ECOSYSTEM_START -->
| Repo | Description | Latest | Install |
|---|---|---|---|
| [cast-hooks](https://github.com/ek33450505/cast-hooks) | 13 auditable hook scripts — observability, safety guards, quality gates. SessionStart, PreToolUse, PostToolUse, PostCompact. | ![](https://img.shields.io/github/v/release/ek33450505/cast-hooks?style=flat-square) | `brew tap ek33450505/cast-hooks && brew install cast-hooks` |
| [cast-agents](https://github.com/ek33450505/cast-agents) | 23 specialist agents — commit, debug, review, plan, test, research, and more. Agent definitions with YAML frontmatter. v7-synced. | ![](https://img.shields.io/github/v/release/ek33450505/cast-agents?style=flat-square) | `brew tap ek33450505/cast-agents && brew install cast-agents` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent agent memory with FTS5 search, relevance scoring, shared pool, semantic embeddings. Per-agent knowledge accumulation. | ![](https://img.shields.io/github/v/release/ek33450505/cast-memory?style=flat-square) | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-routines](https://github.com/ek33450505/cast-routines) | Scheduled autonomous Claude Code routines via YAML + cron. Daily briefings, inbox triage, release celebration, weekly cost reports. | ![](https://img.shields.io/github/v/release/ek33450505/cast-routines?style=flat-square) | `brew tap ek33450505/cast-routines && brew install cast-routines` |
| [cast-parallel](https://github.com/ek33450505/cast-parallel) | Parallel agent execution across worktree sessions. Agent Dispatch Manifest (ADM) support. | ![](https://img.shields.io/github/v/release/ek33450505/cast-parallel?style=flat-square) | `brew tap ek33450505/cast-parallel && brew install cast-parallel` |
| [cast-observe](https://github.com/ek33450505/cast-observe) | Session-level observability — cost tracking, agent run history, token spend, event sourcing. Feeds cast.db. | ![](https://img.shields.io/github/v/release/ek33450505/cast-observe?style=flat-square) | `brew tap ek33450505/cast-observe && brew install cast-observe` |
| [cast-security](https://github.com/ek33450505/cast-security) | Security hooks and audit trails. PII redaction, parry-guard integration, compliance logging. | ![](https://img.shields.io/github/v/release/ek33450505/cast-security?style=flat-square) | `brew tap ek33450505/cast-security && brew install cast-security` |
| [cast-doctor](https://github.com/ek33450505/cast-doctor) | Read-only health check for any Claude Code install. Validates hooks, MCP servers, agent frontmatter, cast.db schema, stale memories. | ![](https://img.shields.io/github/v/release/ek33450505/cast-doctor?style=flat-square) | `brew tap ek33450505/cast-doctor && brew install cast-doctor` |
| [cast-time](https://github.com/ek33450505/cast-time) | Gives Claude Code a clock — injects local time, timezone, and a semantic time-of-day bucket at every SessionStart. | ![](https://img.shields.io/github/v/release/ek33450505/cast-time?style=flat-square) | `brew tap ek33450505/cast-time && brew install cast-time` |
| [cast-dash](https://github.com/ek33450505/cast-dash) | Terminal UI dashboard for live swarm monitoring. 4-panel real-time display (Textual framework). | ![](https://img.shields.io/github/v/release/ek33450505/cast-dash?style=flat-square) | `brew tap ek33450505/cast-dash && brew install cast-dash` |
| [cast-claudes_journal](https://github.com/ek33450505/cast-claudes_journal) | Session continuity — Claude's Journal auto-injects prior-day context via SessionStart hook. Obsidian vault sync. | ![](https://img.shields.io/github/v/release/ek33450505/cast-claudes_journal?style=flat-square) | `brew tap ek33450505/homebrew-claudes-journal && brew install claudes-journal` |
| [cast-website](https://github.com/ek33450505/cast-website) | castframework.dev — marketing site and docs portal for the CAST ecosystem. | ![](https://img.shields.io/github/v/release/ek33450505/cast-website?style=flat-square) | — |
| [cast-desktop](https://github.com/ek33450505/cast-desktop) | Tauri 2 native app — embedded PTY terminal, command palette, 11 dashboard views, Constellation 3D graph. NEW. | ![](https://img.shields.io/github/v/release/ek33450505/cast-desktop?style=flat-square) | `brew tap ek33450505/homebrew-cast-desktop && brew install cast-desktop` |
<!-- ECOSYSTEM_END -->

## License

MIT — see [LICENSE](LICENSE)
