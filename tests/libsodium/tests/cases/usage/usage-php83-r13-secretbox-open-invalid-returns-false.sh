#!/usr/bin/env bash
# @testcase: usage-php83-r13-secretbox-open-invalid-returns-false
# @title: PHP sodium_crypto_secretbox_open returns false for ciphertext under the wrong key
# @description: Encrypts a payload with sodium_crypto_secretbox under one 32-byte key, attempts to decrypt with a different 32-byte key, asserts the call returns boolean false, then confirms the original key recovers the plaintext.
# @timeout: 60
# @tags: usage, crypto, secretbox, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$key = str_repeat("\x11", SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$wrong = str_repeat("\x22", SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$nonce = str_repeat("\x33", SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$plain = "php r13 secretbox-open invalid-key payload";

$ct = sodium_crypto_secretbox($plain, $nonce, $key);
if ($ct === $plain) { fwrite(STDERR, "ct == plain\n"); exit(1); }

$bad = sodium_crypto_secretbox_open($ct, $nonce, $wrong);
if ($bad !== false) {
  fwrite(STDERR, "expected false on wrong key, got: " . var_export($bad, true) . "\n");
  exit(1);
}

$ok = sodium_crypto_secretbox_open($ct, $nonce, $key);
if ($ok !== $plain) { fwrite(STDERR, "round-trip mismatch\n"); exit(1); }
echo "ok\n";
'
