# AGENTS.md - Development Guidelines

## Project Overview
Bash scripting repository following modern shell development standards.

## Build/Lint/Test Commands

### Linting & Formatting
```bash
# Lint all shell scripts
shellcheck script.sh

# Format shell scripts (2-space indent)
shfmt -i 2 -w script.sh

# Lint and format in one pass
shellcheck script.sh && shfmt -i 2 -w script.sh
```

### Testing
```bash
# Run all tests (if using bats)
bats tests/

# Run single test file
bats tests/test-name.bats

# Run single test case
bats tests/test-name.bats -f "test description"

# Run with verbose output
bats -v tests/
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
- Use uppercase for global constants, lowercase for local variables
- Initialize variables before use

### Arrays
- Prefer arrays over string splitting:
  ```bash
  files=("file1" "file2" "file3")
  for file in "${files[@]}"; do
    echo "$file"
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
- Document parameters in comments

### File Operations
- Quote file paths with spaces: `"/path/with spaces/file"`
- Use `mkdir -p` for directory creation
- Prefer `>>` for appending, `>` for overwriting
- Use `readlink -f` for absolute paths

### Process Management
- Use `&` for background processes
- Track PIDs and wait for completion
- Use `wait` to collect exit codes

## Security

- Never use `eval` with untrusted input
- Sanitize user input before command substitution
- Use `printf` instead of `echo` for predictable output
- Avoid `rm -rf` - use safer alternatives
- Set restrictive permissions: `chmod 700` for scripts

## Best Practices

- Keep functions under 100 lines
- One responsibility per function
- Use `command -v` to check for external commands
- Prefer builtins over external commands when possible
- Add comments for complex logic, not obvious operations
- Use `printf '%s\n' "$var"` for portable output

## Git Workflow

- Use feature branches for all changes
- Commit messages in imperative mood, ≤72 chars
- Run `shellcheck` and `shfmt` before committing
- No secrets or credentials in scripts

## Dependencies

- Minimize external dependencies
- Check for required commands at script start using `command -v`:
  ```bash
  check_dependencies() {
    local missing=()
    for cmd in curl jq; do
      if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
      fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      printf 'Error: missing required commands: %s\n' "${missing[*]}" >&2
      return 1
    fi
  }
  ```
- Use `#!/usr/bin/env bash` for portability over `#!/bin/bash`