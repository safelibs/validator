#!/usr/bin/env bash
# @testcase: usage-php83-sodium-generichash
# @title: PHP sodium generichash
# @description: Runs PHP sodium generichash cryptography through libsodium.
# @timeout: 180
# @tags: usage, crypto
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php -r "echo sodium_bin2hex(sodium_crypto_generichash('payload')), PHP_EOL;"
