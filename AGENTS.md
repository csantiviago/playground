# AGENTS.md - Development Guidelines

## Project Overview
Bash scripting repository following modern shell development standards.

## Build/Lint/Test Commands

### Linting & Formatting
```bash
# Lint a single script
shellcheck script.sh

# Format a single script (2-space indent)
shfmt -i 2 -w script.sh

# Lint and format all scripts in the repo
shellcheck *.sh && shfmt -i 2 -w *.sh
```

### Testing
```bash
# Run all tests
bats tests/

# Run single test file
bats tests/test-name.bats

# Run single test case
bats tests/test-name.bats -f "test description"

# Run with verbose output
bats --verbose-run tests/
```

### Installation (if needed)
```bash
# Install bats test framework
sudo apt install bats  # Debian/Ubuntu
```

## Code Style Guidelines

### Script Structure
- Always start with `set -euo pipefail` for strict error handling
- Include shebang: `#!/usr/bin/env bash`
- Add brief description as first comment after shebang
- Use functions for reusable logic
- Place functions at top, main execution at bottom

### Error Handling
- Use `set -euo pipefail` at script start
- Check command exit codes explicitly for critical operations
- Provide clear error messages with context to stderr (`>&2`)
- Use `trap` for cleanup on exit:
  ```bash
  trap 'rm -f /tmp/tempfile' EXIT
  ```
- For network calls, always set timeouts: `curl --max-time 10 --connect-timeout 5`
- Use `curl --fail` to treat HTTP 4xx/5xx as errors

### Variables
- Use `local` for function-scoped variables
- Quote all variable expansions: `"$var"` not `$var`
- Use `readonly` for global constants, `local` for function-scoped variables
- Initialize variables before use

### Arrays
- Prefer arrays over string splitting:
  ```bash
  files=("file1" "file2" "file3")
  for file in "${files[@]}"; do
    printf '%s\n' "$file"
  done
  ```

### Conditionals
- Use `[[ ]]` for conditionals (bash-specific but safer)
- Quote patterns in `case` statements
- Avoid nesting; use early returns

### Functions
- Use descriptive names with underscores: `process_files()`
- Return exit codes (0 success, non-zero failure)
- Output results via stdout, not global variables

### File Operations
- Quote file paths with spaces: `"/path/with spaces/file"`
- Use `mkdir -p` for directory creation
- Prefer `>>` for appending, `>` for overwriting
- Use `readlink -f` for absolute paths

## Security

- Never use `eval` with untrusted input
- Sanitize user input before command substitution
- Use `printf` instead of `echo` for predictable output
- Avoid `rm -rf` — use safer alternatives like `trash`
- Set restrictive permissions: `chmod 700` for scripts

## Best Practices

- Keep functions under 100 lines
- One responsibility per function
- Use `command -v` to check for external commands
- Prefer builtins over external commands when possible
- Use `printf '%s\n' "$var"` for portable output

## Git Workflow

- Use feature branches for all changes
- Commit messages in imperative mood, ≤72 chars
- Always include `Assisted-by: opencode with qwen3.5-27b` trailer in commits
- Run `shellcheck *.sh && shfmt -d *.sh` before committing
- No secrets or credentials in scripts

## Dependencies

- Minimize external dependencies
- Check for required commands at script start using `command -v`:
  ```bash
  check_dependencies() {
    local deps=("$@")
    local missing=()
    for cmd in "${deps[@]}"; do
      if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
      fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      printf 'Error: missing required commands: %s\n' "${missing[*]}" >&2
      return 1
    fi
  }
  # Usage: check_dependencies curl jq numfmt
  ```
- Use `#!/usr/bin/env bash` for portability over `#!/bin/bash`
