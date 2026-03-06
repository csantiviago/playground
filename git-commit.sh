#!/usr/bin/env bash
set -euo pipefail

# Wrapper for git commit that adds Assisted-by trailer
# Usage: git-commit.sh [-m "message"] [options]
# Environment: MODEL_NAME (optional, default: opencode with qwen3.5-27b)

readonly MODEL_NAME="${MODEL_NAME:-opencode with qwen3.5-27b}"
readonly TRAILER="Assisted-by: ${MODEL_NAME}"

main() {
  # Check if we have a message
  if [[ $# -eq 0 ]] || [[ "$1" != "-m" && "$1" != "--message" ]]; then
    # No message provided, use interactive commit
    if git commit --template=.git/COMMIT_MSG "$@"; then
      git commit --amend --no-edit --trailer "${TRAILER}"
    fi
  else
    # Message provided
    local msg=""
    shift
    if [[ "$1" == "-m" || "$1" == "--message" ]]; then
      shift
      msg="$1"
      shift
    fi

    # Create commit with message and trailer
    git commit -m "${msg}" -m "${TRAILER}" "$@"
  fi
}

main "$@"
