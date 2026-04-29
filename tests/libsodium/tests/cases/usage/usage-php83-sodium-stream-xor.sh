#!/usr/bin/env bash
# @testcase: usage-php83-sodium-stream-xor
# @title: PHP sodium stream xor
# @description: Encrypts and decrypts a short payload with PHP sodium stream-xor APIs and verifies round-trip parity.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-stream-xor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_STREAM_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_STREAM_NONCEBYTES);
$cipher = sodium_crypto_stream_xor('stream payload', $nonce, $key);
$plain = sodium_crypto_stream_xor($cipher, $nonce, $key);
if ($plain !== 'stream payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
