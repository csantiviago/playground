#!/usr/bin/env bash
set -euo pipefail

# Fetch current Bitcoin price from CoinGecko API

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

fetch_bitcoin_price() {
  local url="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
  local response
  response=$(curl --silent --fail --max-time 10 --connect-timeout 5 "${url}")

  local price
  price=$(jq -r '.bitcoin.usd' <<<"${response}")

  if [[ "${price}" == "null" || -z "${price}" ]]; then
    printf 'Error: failed to parse Bitcoin price from response\n' >&2
    return 1
  fi

  printf '%s\n' "${price}"
}

main() {
  check_dependencies
  local price
  price=$(fetch_bitcoin_price)
  printf 'Bitcoin price: $%s\n' "$(numfmt --grouping "${price}")"
}

main "$@"
