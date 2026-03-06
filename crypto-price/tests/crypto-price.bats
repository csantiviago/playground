#!/usr/bin/env bats
load /tmp/bats-support/load.bash
load /tmp/bats-assert/load.bash

SCRIPT_NAME="crypto-price.sh"

setup() {
  SCRIPT_PATH="$(dirname "$BATS_TEST_FILENAME")/../${SCRIPT_NAME}"
  
  # Create mock curl that returns test data
  mkdir -p /tmp/bats-mock
  cat > /tmp/bats-mock/curl << 'MOCK'
#!/bin/bash
# Mock curl - returns test data based on URL
for arg in "$@"; do
  if [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *usd* ]]; then
    echo '{"bitcoin":{"usd":"68475"}}'
    exit 0
  elif [[ "$arg" == *ethereum* ]] && [[ "$arg" == *usd* ]]; then
    echo '{"ethereum":{"usd":"1973.36"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *eur* ]]; then
    echo '{"bitcoin":{"eur":"62500"}}'
    exit 0
  elif [[ "$arg" == *ethereum* ]] && [[ "$arg" == *eur* ]]; then
    echo '{"ethereum":{"eur":"1800"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *gbp* ]]; then
    echo '{"bitcoin":{"gbp":"54000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *jpy* ]]; then
    echo '{"bitcoin":{"jpy":"10500000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *cny* ]]; then
    echo '{"bitcoin":{"cny":"490000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *krw* ]]; then
    echo '{"bitcoin":{"krw":"95000000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *inr* ]]; then
    echo '{"bitcoin":{"inr":"5700000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *brl* ]]; then
    echo '{"bitcoin":{"brl":"350000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *aud* ]]; then
    echo '{"bitcoin":{"aud":"105000"}}'
    exit 0
  elif [[ "$arg" == *bitcoin* ]] && [[ "$arg" == *cad* ]]; then
    echo '{"bitcoin":{"cad":"95000"}}'
    exit 0
  elif [[ "$arg" == *invalid* ]]; then
    echo '{}'
    exit 0
  elif [[ "$arg" == *xyz* ]]; then
    echo '{"bitcoin":{}}'
    exit 0
  fi
done
echo '{}'
exit 0
MOCK
  chmod +x /tmp/bats-mock/curl
  
  # Create mock jq
  cat > /tmp/bats-mock/jq << 'MOCK'
#!/bin/bash
# Mock jq - extracts value from JSON
input=$(cat)
key=""
for arg in "$@"; do
  case "$arg" in
    -r|-e|--raw|--exit-status)
      ;;
    .*)
      key="$arg"
      ;;
  esac
done
if [[ "$key" == ".bitcoin.usd" ]]; then
  echo '68475'
elif [[ "$key" == ".ethereum.usd" ]]; then
  echo '1973.36'
elif [[ "$key" == ".bitcoin.eur" ]]; then
  echo '62500'
elif [[ "$key" == ".ethereum.eur" ]]; then
  echo '1800'
elif [[ "$key" == ".bitcoin.gbp" ]]; then
  echo '54000'
elif [[ "$key" == ".bitcoin.jpy" ]]; then
  echo '10500000'
elif [[ "$key" == ".bitcoin.cny" ]]; then
  echo '490000'
elif [[ "$key" == ".bitcoin.krw" ]]; then
  echo '95000000'
elif [[ "$key" == ".bitcoin.inr" ]]; then
  echo '5700000'
elif [[ "$key" == ".bitcoin.brl" ]]; then
  echo '350000'
elif [[ "$key" == ".bitcoin.aud" ]]; then
  echo '105000'
elif [[ "$key" == ".bitcoin.cad" ]]; then
  echo '95000'
else
  exit 1
fi
MOCK
  chmod +x /tmp/bats-mock/jq
  
  # Add mock to PATH
  export PATH="/tmp/bats-mock:$PATH"
}

teardown() {
  rm -rf /tmp/bats-mock
}

@test "show help with --help" {
  run bash "${SCRIPT_PATH}" --help
  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "Fetch current cryptocurrency prices"
}

@test "show help with -h" {
  run bash "${SCRIPT_PATH}" -h
  assert_success
  assert_output --partial "Usage:"
}

@test "default coin is bitcoin" {
  run bash "${SCRIPT_PATH}" --raw
  assert_success
  assert_output "68475"
}

@test "unknown option shows error" {
  run bash "${SCRIPT_PATH}" --unknown
  assert_failure
  assert_output --partial "Error: unknown option"
}

@test "coin option works with -c" {
  run bash "${SCRIPT_PATH}" -c ethereum --raw
  assert_success
  assert_output "1973.36"
}

@test "coin option works with --coin" {
  run bash "${SCRIPT_PATH}" --coin ethereum --raw
  assert_success
  assert_output "1973.36"
}

@test "currency option works with -u" {
  run bash "${SCRIPT_PATH}" -u eur --raw
  assert_success
  assert_output "62500"
}

@test "currency option works with --currency" {
  run bash "${SCRIPT_PATH}" --currency eur --raw
  assert_success
  assert_output "62500"
}

@test "fetch_price with valid coin and currency" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u usd --raw
  assert_success
  assert_output "68475"
}

@test "fetch_price with invalid coin shows error" {
  run bash "${SCRIPT_PATH}" -c invalidcoin123 -u usd --raw 2>&1
  assert_failure
  assert_output --partial "Error:"
}

@test "fetch_price with invalid currency shows error" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u xyz --raw 2>&1
  assert_failure
  assert_output --partial "Error:"
}

@test "format_price with USD symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u usd
  assert_success
  assert_output --partial "$"
  assert_output --partial "68,475"
}

@test "format_price with EUR symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u eur
  assert_success
  assert_output --partial "€"
  assert_output --partial "62,500"
}

@test "format_price with GBP symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u gbp
  assert_success
  assert_output --partial "£"
  assert_output --partial "54,000"
}

@test "format_price with JPY symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u jpy
  assert_success
  assert_output --partial "¥"
  assert_output --partial "10,500,000"
}

@test "format_price with CNY symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u cny
  assert_success
  assert_output --partial "¥"
  assert_output --partial "490,000"
}

@test "format_price with KRW symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u krw
  assert_success
  assert_output --partial "₩"
  assert_output --partial "95,000,000"
}

@test "format_price with INR symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u inr
  assert_success
  assert_output --partial "₹"
  assert_output --partial "5,700,000"
}

@test "format_price with BRL symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u brl
  assert_success
  assert_output --partial "R$"
  assert_output --partial "350,000"
}

@test "format_price with AUD symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u aud
  assert_success
  assert_output --partial "A$"
  assert_output --partial "105,000"
}

@test "format_price with CAD symbol" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u cad
  assert_success
  assert_output --partial "C$"
  assert_output --partial "95,000"
}

@test "raw output with -r flag" {
  run bash "${SCRIPT_PATH}" -r
  assert_success
  assert_output "68475"
}

@test "raw output with --raw flag" {
  run bash "${SCRIPT_PATH}" --raw
  assert_success
  assert_output "68475"
}

@test "coin name is case insensitive" {
  run bash "${SCRIPT_PATH}" -c BITCOIN -u usd --raw
  assert_success
  assert_output "68475"
}

@test "currency code is case insensitive" {
  run bash "${SCRIPT_PATH}" -c bitcoin -u USD --raw
  assert_success
  assert_output "68475"
}

@test "combined options work together" {
  run bash "${SCRIPT_PATH}" -c ethereum -u eur
  assert_success
  assert_output --partial "Ethereum:"
  assert_output --partial "€"
}

@test "usage shows examples" {
  run bash "${SCRIPT_PATH}" --help
  assert_success
  assert_output --partial "Examples:"
}

@test "usage shows default coin" {
  run bash "${SCRIPT_PATH}" --help
  assert_success
  assert_output --partial "bitcoin"
}

@test "usage shows default currency" {
  run bash "${SCRIPT_PATH}" --help
  assert_success
  assert_output --partial "usd"
}