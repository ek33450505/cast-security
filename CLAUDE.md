# cast-security

Standalone security audit and policy management tool for CAST. Works independently without full CAST installation.

## Quick Start

```bash
# Install
bash install.sh

# Test (3 project-owned BATS files; tests/bats/ is framework submodule)
bats tests/cli.bats && bats tests/hooks.bats && bats tests/install.bats

# Run
cast-security status          # show security status
cast-security audit [paths]   # audit files/dirs
cast-security redact <file>   # mask PII in logs
cast-security policies        # list security policies
```

## Key Design

- **Standalone first** — no dependency on full CAST installation
- **Subcommands:** status, audit, redact, policies
- **Tests:** isolated temp HOME per test suite (BATS convention)
- **Scripts:** shell-based auditing and PII redaction in `scripts/`

## Install Behavior

`bash install.sh` links `bin/cast-security` to `~/.local/bin/` and creates `~/.cast-security/` config directory.

## References

- **Install:** `install.sh` (completes in ~30 seconds)
- **Subcommands:** `bin/cast-security` (14.6 KB)
- **Policies:** `config/` (default and custom rulesets)
- **Changelog:** `CHANGELOG.md`
