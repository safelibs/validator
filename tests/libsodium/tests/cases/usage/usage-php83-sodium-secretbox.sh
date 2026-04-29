#!/usr/bin/env bash
# @testcase: usage-php83-sodium-secretbox
# @title: PHP sodium secretbox
# @description: Runs PHP sodium secretbox cryptography through libsodium.
# @timeout: 180
# @tags: usage, crypto
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php -r '$key=random_bytes(SODIUM_CRYPTO_SECRETBOX_KEYBYTES); $nonce=random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES); $c=sodium_crypto_secretbox("payload",$nonce,$key); echo sodium_crypto_secretbox_open($c,$nonce,$key),PHP_EOL;'
