# Security Policy

## Supported Versions

| Version | Support Status |
|---|---|
| 0.3.x | Full support — security fixes backported |
| < 0.3 | No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately using [GitHub Security Advisories](https://github.com/ek33450505/cast-security/security/advisories/new).

### What to Include

- **cast-security version** — output of `cast-security --version`
- **Operating system** — macOS / Linux, version
- **Which hook or script** — e.g., `cast-security-guard.sh`, `cast-audit-hook.sh`, `cast-redact.py`
- **Steps to reproduce** — minimal, clear reproduction steps
- **Impact** — what an attacker could do

### Response Timeline

| Severity | Acknowledgment | Fix Target |
|---|---|---|
| Critical | 48 hours | 14 days |
| High | 48 hours | 30 days |
| Medium / Low | 5 business days | Next release |

## Security Design Notes

cast-security is itself a security tool. Key design decisions that prevent it from becoming an attack surface:

- **No shell variable interpolation into Python heredocs** — all dynamic data passes through environment variables to prevent injection via crafted tool inputs
- **Advisory-first** — `cast-security-guard.sh` always exits 0; it cannot be weaponized to deny legitimate tool calls
- **Fail-open** — all hooks use `set +e` and must never interrupt Claude Code on error
- **No remote calls** — cast-security makes no network requests; all detection is local
- **PII is hashed, not stored** — `cast-audit-hook.sh` stores SHA256 of file content, never raw content

## Out of Scope

- Vulnerabilities in the Claude API or Anthropic services — report to [Anthropic](https://www.anthropic.com/security)
- Vulnerabilities in third-party tools (Python, bash, Microsoft Presidio)
- Issues requiring physical access to the machine
