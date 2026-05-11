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

Each CAST component ships as a standalone Homebrew package. Mix and match to build your own stack.

| Package | What It Does | Install |
|---------|-------------|---------|
| [cast-agents](https://github.com/ek33450505/cast-agents) | 17 specialist Claude Code agents | `brew tap ek33450505/cast-agents && brew install cast-agents` |
| [cast-hooks](https://github.com/ek33450505/cast-hooks) | 13 hook scripts — observability, safety gates, dispatch | `brew tap ek33450505/cast-hooks && brew install cast-hooks` |
| [cast-observe](https://github.com/ek33450505/cast-observe) | Session cost + token spend tracking | `brew tap ek33450505/cast-observe && brew install cast-observe` |
| **cast-security** | Policy gates, PII redaction, audit trail | `brew tap ek33450505/cast-security && brew install cast-security` |
| [cast-dash](https://github.com/ek33450505/cast-dash) | Terminal UI dashboard (Python + Textual) | `brew tap ek33450505/cast-dash && brew install cast-dash` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent memory for Claude Code agents | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-parallel](https://github.com/ek33450505/cast-parallel) | Parallel plan execution across dual worktrees | `brew tap ek33450505/cast-parallel && brew install cast-parallel` |

## License

MIT — see [LICENSE](LICENSE)
