#!/usr/bin/env bash
# @testcase: usage-php83-r9-secretbox-tampered-fails
# @title: PHP sodium_crypto_secretbox tampered ciphertext rejected
# @description: Encrypts a payload with sodium_crypto_secretbox, mutates the ciphertext, and verifies sodium_crypto_secretbox_open returns false on the tampered input.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
$key = sodium_crypto_secretbox_keygen();
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$msg = 'php sodium r9 payload';
$ct = sodium_crypto_secretbox($msg, $nonce, $key);
$plain = sodium_crypto_secretbox_open($ct, $nonce, $key);
if ($plain !== $msg) { fwrite(STDERR, "original failed\n"); exit(1); }

$tampered = $ct;
$tampered[5] = chr(ord($tampered[5]) ^ 0x01);
$bad = sodium_crypto_secretbox_open($tampered, $nonce, $key);
if ($bad !== false) { fwrite(STDERR, "tampered accepted\n"); exit(2); }
echo "ok\n";
PHP
