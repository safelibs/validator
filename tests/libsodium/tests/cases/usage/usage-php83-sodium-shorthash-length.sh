#!/usr/bin/env bash
# @testcase: usage-php83-sodium-shorthash-length
# @title: php83 sodium shorthash length
# @description: Calls PHP sodium_crypto_shorthash with a 16 byte key and verifies the SHORTHASH_BYTES output length.
# @timeout: 180
# @tags: usage, php, hash
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-shorthash-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = str_repeat("\x42", SODIUM_CRYPTO_SHORTHASH_KEYBYTES);
$h = sodium_crypto_shorthash('payload', $key);
if (strlen($h) !== SODIUM_CRYPTO_SHORTHASH_BYTES) { exit(1); }
echo strlen($h), PHP_EOL;
PHP
