#!/usr/bin/env bash
# @testcase: usage-php83-sodium-shorthash
# @title: PHP sodium shorthash
# @description: Computes a short keyed hash with PHP sodium and checks the output size.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-shorthash"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_SHORTHASH_KEYBYTES);
$hash = sodium_crypto_shorthash('payload', $key);
if (strlen($hash) !== SODIUM_CRYPTO_SHORTHASH_BYTES) { exit(1); }
echo sodium_bin2hex($hash), PHP_EOL;
PHP
