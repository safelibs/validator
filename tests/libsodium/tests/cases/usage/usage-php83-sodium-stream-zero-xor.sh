#!/usr/bin/env bash
# @testcase: usage-php83-sodium-stream-zero-xor
# @title: PHP sodium stream zero xor
# @description: Generates a PHP libsodium keystream and verifies it matches sodium_crypto_stream_xor applied to an all-zero plaintext buffer.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-stream-zero-xor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_STREAM_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_STREAM_NONCEBYTES);
$stream = sodium_crypto_stream(24, $nonce, $key);
$xor = sodium_crypto_stream_xor(str_repeat("\x00", 24), $nonce, $key);
if ($stream !== $xor) { exit(1); }
echo strlen($stream), PHP_EOL;
PHP
