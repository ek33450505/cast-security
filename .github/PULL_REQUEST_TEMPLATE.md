## Summary

-
-

## Type of Change

- [ ] New security hook
- [ ] PII pattern / policy rule
- [ ] Permission rule change
- [ ] Bug fix
- [ ] Docs only
- [ ] Refactor

## Pre-Merge Checklist

- [ ] `shellcheck` passes on modified shell scripts
- [ ] Python scripts pass `ruff check` or `flake8`
- [ ] Hook exits 0 with empty stdin (advisory hooks)
- [ ] Exit code 2 only for intended blocking behavior
- [ ] No hardcoded paths (use `$HOME` or `~/`)
- [ ] `CHANGELOG.md` updated for user-visible changes
