#!/usr/bin/env bash
# @testcase: usage-php83-sodium-kdf
# @title: PHP sodium KDF
# @description: Derives multiple subkeys from one master key with the PHP sodium KDF helpers.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-kdf"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_KDF_KEYBYTES);
$subkey1 = sodium_crypto_kdf_derive_from_key(32, 1, 'CTXTEST1', $key);
$subkey2 = sodium_crypto_kdf_derive_from_key(32, 2, 'CTXTEST1', $key);
if (strlen($subkey1) !== 32 || strlen($subkey2) !== 32 || $subkey1 === $subkey2) { exit(1); }
echo strlen($subkey1), PHP_EOL;
PHP
