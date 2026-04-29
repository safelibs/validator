#!/usr/bin/env bash
# @testcase: usage-php83-sodium-keyed-generichash
# @title: PHP sodium keyed generichash
# @description: Computes keyed generic hashes with PHP sodium and verifies distinct inputs produce different outputs.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-keyed-generichash"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_GENERICHASH_KEYBYTES);
$hash = sodium_crypto_generichash('payload', $key, 16);
$other = sodium_crypto_generichash('other', $key, 16);
if (strlen($hash) !== 16 || $hash === $other) { exit(1); }
echo sodium_bin2hex($hash), PHP_EOL;
PHP
