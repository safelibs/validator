#!/usr/bin/env bash
# @testcase: usage-php83-sodium-secretbox-wrong-key-fails
# @title: PHP sodium_crypto_secretbox_open returns false for wrong key
# @description: Encrypts a payload with sodium_crypto_secretbox under a fixed key and nonce, asserts sodium_crypto_secretbox_open recovers the plaintext exactly under the correct key, and asserts open returns boolean false (rather than throwing or silently returning corrupted bytes) when called with a different 32-byte key. Also asserts open returns false when the ciphertext is mutated by a single byte under the correct key.
# @timeout: 180
# @tags: usage, crypto, secretbox, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key       = str_repeat("\x11", SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$wrong_key = str_repeat("\x22", SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$nonce     = str_repeat("\x33", SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$plain     = 'secretbox wrong-key payload';

$ct = sodium_crypto_secretbox($plain, $nonce, $key);
if (strlen($ct) !== strlen($plain) + SODIUM_CRYPTO_SECRETBOX_MACBYTES) {
    fwrite(STDERR, "unexpected ciphertext length: " . strlen($ct) . "\n");
    exit(1);
}

$pt = sodium_crypto_secretbox_open($ct, $nonce, $key);
if ($pt !== $plain) {
    fwrite(STDERR, "correct-key decrypt mismatch\n");
    exit(1);
}

$bad = sodium_crypto_secretbox_open($ct, $nonce, $wrong_key);
if ($bad !== false) {
    fwrite(STDERR, "open under wrong key did not return false: " . var_export($bad, true) . "\n");
    exit(1);
}

// Tamper a single ciphertext byte and confirm open fails under the right key.
$ct_tampered = $ct;
$ct_tampered[0] = chr(ord($ct_tampered[0]) ^ 0xFF);
if ($ct_tampered === $ct) {
    fwrite(STDERR, "tamper had no effect\n"); exit(1);
}
$bad2 = sodium_crypto_secretbox_open($ct_tampered, $nonce, $key);
if ($bad2 !== false) {
    fwrite(STDERR, "open of tampered ciphertext did not return false\n");
    exit(1);
}

echo "ok ", strlen($ct), PHP_EOL;
PHP
