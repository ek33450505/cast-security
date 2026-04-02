#!/bin/bash
# install.sh — cast-security manual installer
# For users who clone the repo instead of using Homebrew.
# Completes in under 30 seconds.
#
# Usage: bash install.sh

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CS_VERSION="$(cat "${REPO_DIR}/VERSION" 2>/dev/null || echo "unknown")"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'
  C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_fail() { printf "${C_RED}  [fail]${C_RESET} %s\n" "$*" >&2; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

# ── Banner ────────────────────────────────────────────────────────────────────
printf "\n${C_BOLD}cast-security v${CS_VERSION} installer${C_RESET}\n"
printf "══════════════════════════════════════\n\n"

# ── Step 1: Check prerequisites ───────────────────────────────────────────────
_step "Checking prerequisites..."
if command -v python3 >/dev/null 2>&1; then
  _ok "python3 found ($(python3 --version 2>&1))"
else
  _warn "python3 not found — PII redaction (cast-redact.py) will be unavailable"
fi
if command -v sqlite3 >/dev/null 2>&1; then
  _ok "sqlite3 found"
else
  _warn "sqlite3 not found — optional; not required for cast-security"
fi

# ── Step 2: Create directories ────────────────────────────────────────────────
_step "Creating directories..."
for dir in \
  "${HOME}/.claude/scripts" \
  "${HOME}/.claude/config" \
  "${HOME}/.claude/cast-security" \
  "${HOME}/.claude/cast-security/hook-last-fired" \
  "${HOME}/.claude/logs"
do
  if mkdir -p "$dir" 2>/dev/null; then
    _ok "~/.claude/${dir##*/.claude/}"
  else
    _fail "Could not create $dir"
  fi
done

# ── Step 3: Copy scripts ──────────────────────────────────────────────────────
_step "Installing scripts..."
copied=0
errors=0
for f in \
  "${REPO_DIR}/scripts/cast-security-guard.sh" \
  "${REPO_DIR}/scripts/cast-permission-hook.sh" \
  "${REPO_DIR}/scripts/cast-audit-hook.sh" \
  "${REPO_DIR}/scripts/cast-redact.py"; do
  [ -f "$f" ] || continue
  dest="${HOME}/.claude/scripts/$(basename "$f")"
  if cp "$f" "$dest" 2>/dev/null; then
    chmod +x "$dest" 2>/dev/null || true
    _ok "$(basename "$f")"
    copied=$((copied + 1))
  else
    _fail "Could not copy $(basename "$f")"
    errors=$((errors + 1))
  fi
done
if [ "$errors" -gt 0 ]; then
  _warn "${errors} script(s) failed to copy — check permissions on ~/.claude/scripts/"
fi

# ── Step 4: Copy config files ─────────────────────────────────────────────────
_step "Installing config..."
for cfg in pii-patterns.json policies.json; do
  src="${REPO_DIR}/config/${cfg}"
  dst="${HOME}/.claude/config/${cfg}"
  if [ -f "$src" ]; then
    if cp "$src" "$dst" 2>/dev/null; then
      _ok "${cfg} → ~/.claude/config/"
    else
      _warn "Could not copy ${cfg}"
    fi
  fi
done

# ── Step 5: Merge settings.json ───────────────────────────────────────────────
_step "Merging settings.json..."
SETTINGS_SRC="${REPO_DIR}/settings.json"
SETTINGS_DST="${HOME}/.claude/settings.json"

if [ ! -f "$SETTINGS_SRC" ]; then
  _warn "settings.json not found in repo — skipping"
elif [ ! -f "$SETTINGS_DST" ]; then
  if cp "$SETTINGS_SRC" "$SETTINGS_DST" 2>/dev/null; then
    _ok "settings.json created at ~/.claude/settings.json"
  else
    _fail "Could not write ~/.claude/settings.json"
  fi
else
  # Non-destructive merge — add cast-security hooks, do not overwrite existing hooks
  if SETTINGS_SRC="$SETTINGS_SRC" SETTINGS_DST="$SETTINGS_DST" \
     python3 - <<'PYEOF' 2>/dev/null; then
import json, os, sys

src_path = os.environ['SETTINGS_SRC']
dst_path = os.environ['SETTINGS_DST']

try:
    with open(src_path) as f:
        src = json.load(f)
    with open(dst_path) as f:
        dst = json.load(f)
except Exception as e:
    print(f"Error reading JSON: {e}", file=sys.stderr)
    sys.exit(1)

src_hooks = src.get('hooks', {})
dst_hooks = dst.setdefault('hooks', {})

merged = 0
for event, event_hooks in src_hooks.items():
    if event not in dst_hooks:
        dst_hooks[event] = event_hooks
        merged += 1
    else:
        # Append cast-security hook groups not already present (check by command string)
        existing_commands = set()
        for group in dst_hooks[event]:
            for hook in group.get('hooks', []):
                existing_commands.add(hook.get('command', ''))
        for group in event_hooks:
            for hook in group.get('hooks', []):
                if hook.get('command', '') not in existing_commands:
                    dst_hooks[event].append(group)
                    merged += 1
                    break

with open(dst_path, 'w') as f:
    json.dump(dst, f, indent=2)
    f.write('\n')

print(f"Merged {merged} hook event(s)")
PYEOF
    _ok "settings.json hooks merged (existing hooks preserved)"
  else
    _warn "settings.json merge failed — manually copy hooks from ${REPO_DIR}/settings.json to ~/.claude/settings.json"
  fi
fi

# ── Step 6: Symlink CLI ────────────────────────────────────────────────────────
_step "Installing CLI..."
LOCAL_BIN="${HOME}/.local/bin"
CLI_SRC="${REPO_DIR}/bin/cast-security"
CLI_DST="${LOCAL_BIN}/cast-security"

if mkdir -p "$LOCAL_BIN" 2>/dev/null; then
  if ln -sf "$CLI_SRC" "$CLI_DST" 2>/dev/null; then
    _ok "cast-security → ~/.local/bin/cast-security"
    if ! echo "$PATH" | grep -q "${LOCAL_BIN}"; then
      printf "\n  ${C_YELLOW}Note:${C_RESET} Add ~/.local/bin to your PATH:\n"
      printf "    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc\n"
    fi
  else
    _warn "Could not symlink to ~/.local/bin — run from repo: ${CLI_SRC}"
  fi
else
  _warn "Could not create ~/.local/bin — run from repo: ${CLI_SRC}"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf "\n${C_BOLD}══════════════════════════════════════${C_RESET}\n"
printf "${C_GREEN}cast-security v${CS_VERSION} installed.${C_RESET}\n\n"
printf "  Scripts: ${HOME}/.claude/scripts/\n"
printf "  Config:  ${HOME}/.claude/config/\n"
printf "  CLI:     ${CLI_DST}\n"
printf "\n${C_BOLD}Next steps:${C_RESET}\n"
printf "  1. Start a Claude Code session\n"
printf "  2. Run: cast-security status\n"
printf "  3. Run: cast-security audit\n\n"
