#!/usr/bin/env bash
set -euo pipefail

# Fetch cryptocurrency prices from CoinGecko API

readonly PROGRAM="${0##*/}"
readonly DEFAULT_COIN="bitcoin"
readonly DEFAULT_CURRENCY="usd"
readonly API_BASE="https://api.coingecko.com/api/v3/simple/price"

# Currency symbols for display
declare -A CURRENCY_SYMBOLS=(
  [usd]='$' [eur]='€' [gbp]='£' [jpy]='¥' [cny]='¥'
  [krw]='₩' [inr]='₹' [brl]='R$' [aud]='A$' [cad]='C$'
)

usage() {
  cat <<EOF
Usage: ${PROGRAM} [OPTIONS]

Fetch current cryptocurrency prices from CoinGecko.

Options:
  -c, --coin COIN          Cryptocurrency (default: ${DEFAULT_COIN})
  -u, --currency CURRENCY  Fiat currency (default: ${DEFAULT_CURRENCY})
  -r, --raw                Output raw number only
  -h, --help               Show this help message

Examples:
  ${PROGRAM}                         Bitcoin in USD
  ${PROGRAM} -c ethereum             Ethereum in USD
  ${PROGRAM} -c solana -u eur        Solana in EUR
  ${PROGRAM} --raw                   Raw price (for piping)
EOF
}

check_dependencies() {
  local missing=()
  for cmd in curl jq numfmt; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'Error: missing required commands: %s\n' "${missing[*]}" >&2
    return 1
  fi
}

fetch_price() {
  local coin="$1"
  local currency="$2"
  local url="${API_BASE}?ids=${coin}&vs_currencies=${currency}"
  local response

  if ! response=$(curl --silent --fail --max-time 10 --connect-timeout 5 "${url}" 2>&1); then
    printf 'Error: failed to reach CoinGecko API (network or HTTP error)\n' >&2
    return 1
  fi

  local price
  price=$(jq -re ".${coin}.${currency}" <<<"${response}" 2>/dev/null) || {
    printf 'Error: coin "%s" or currency "%s" not found\n' "${coin}" "${currency}" >&2
    return 1
  }

  printf '%s\n' "${price}"
}

format_price() {
  local price="$1"
  local currency="$2"
  local symbol="${CURRENCY_SYMBOLS[${currency}]:-}"

  printf '%s%s' "${symbol}" "$(numfmt --grouping "${price}")"
}

main() {
  local coin="${DEFAULT_COIN}"
  local currency="${DEFAULT_CURRENCY}"
  local raw=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -c | --coin)
      coin="${2:?Error: --coin requires an argument}"
      shift 2
      ;;
    -u | --currency)
      currency="${2:?Error: --currency requires an argument}"
      shift 2
      ;;
    -r | --raw)
      raw=true
      shift
      ;;
    -h | --help)
      usage
      return 0
      ;;
    *)
      printf 'Error: unknown option: %s\n' "$1" >&2
      usage >&2
      return 1
      ;;
    esac
  done

  coin="${coin,,}"
  currency="${currency,,}"

  check_dependencies

  local price
  price=$(fetch_price "${coin}" "${currency}")

  if [[ "${raw}" == true ]]; then
    printf '%s\n' "${price}"
    return
  fi

  local label="${coin^}"
  printf '%s: %s\n' "${label}" "$(format_price "${price}" "${currency}")"
}

main "$@"
