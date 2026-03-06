#!/usr/bin/env bash
set -euo pipefail

# Fetch current Bitcoin price from CoinGecko API

fetch_bitcoin_price() {
  local url="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
  local response

  response=$(curl -s "${url}" || return 1)

  local price
  price=$(printf '%s' "${response}" | jq -r '.bitcoin.usd')

  if [[ "${price}" == "null" || -z "${price}" ]]; then
    echo "Error: Failed to parse Bitcoin price" >&2
    return 1
  fi

  printf '%s\n' "${price}"
}

main() {
  local price
  price=$(fetch_bitcoin_price)
  printf 'Bitcoin price: $%s\n' "${price}"
}

main "$@"
