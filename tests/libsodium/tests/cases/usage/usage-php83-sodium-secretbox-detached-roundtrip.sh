#!/usr/bin/env bash
# @testcase: usage-php83-sodium-secretbox-detached-roundtrip
# @title: php83 sodium secretbox roundtrip
# @description: Encrypts a payload with sodium_crypto_secretbox in PHP and verifies the open call decrypts back to the original message.
# @timeout: 180
# @tags: usage, php, secretbox
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-secretbox-detached-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = sodium_crypto_secretbox_keygen();
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$msg = 'tenth batch payload';
$cipher = sodium_crypto_secretbox($msg, $nonce, $key);
$plain = sodium_crypto_secretbox_open($cipher, $nonce, $key);
if ($plain !== $msg) { exit(1); }
echo strlen($cipher), PHP_EOL;
PHP
