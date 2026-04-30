#!/usr/bin/env bash
# @testcase: usage-php83-sodium-aead-aegis-256-capability
# @title: PHP sodium AEGIS-256 AEAD capability-gated roundtrip
# @description: Probes whether PHP's sodium extension exposes sodium_crypto_aead_aegis256_encrypt and the matching SODIUM_CRYPTO_AEAD_AEGIS256_* constants on this build of libsodium; when present, encrypts and decrypts a fixed payload under a fixed 32-byte key, 32-byte nonce, and AAD, asserts the ciphertext is exactly len(plaintext)+ABYTES and decrypts back to the original, and that altering the AAD fails decryption with a false return; when absent (older libsodium), prints a skip marker and succeeds.
# @timeout: 180
# @tags: usage, crypto, aead, aegis, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
if (!function_exists('sodium_crypto_aead_aegis256_encrypt')
    || !function_exists('sodium_crypto_aead_aegis256_decrypt')) {
    echo "aegis256-available 0\n";
    echo "ok skipped (sodium ext lacks aegis256)\n";
    exit(0);
}
$kbytes = defined('SODIUM_CRYPTO_AEAD_AEGIS256_KEYBYTES') ? SODIUM_CRYPTO_AEAD_AEGIS256_KEYBYTES : 32;
$nbytes = defined('SODIUM_CRYPTO_AEAD_AEGIS256_NPUBBYTES') ? SODIUM_CRYPTO_AEAD_AEGIS256_NPUBBYTES : 32;
$abytes = defined('SODIUM_CRYPTO_AEAD_AEGIS256_ABYTES') ? SODIUM_CRYPTO_AEAD_AEGIS256_ABYTES : 32;
echo "aegis256-available 1\n";

$key = str_repeat("\x42", $kbytes);
$nonce = str_repeat("\x11", $nbytes);
$aad = 'validator-aad';
$plain = 'aegis-256 aead payload';

$ct = sodium_crypto_aead_aegis256_encrypt($plain, $aad, $nonce, $key);
if (!is_string($ct)) {
    fwrite(STDERR, "encrypt did not return string\n"); exit(1);
}
if (strlen($ct) !== strlen($plain) + $abytes) {
    fwrite(STDERR, "ciphertext length " . strlen($ct) . " != " . (strlen($plain) + $abytes) . "\n");
    exit(1);
}

$pt = sodium_crypto_aead_aegis256_decrypt($ct, $aad, $nonce, $key);
if ($pt !== $plain) {
    fwrite(STDERR, "decrypt mismatch\n"); exit(1);
}

// Wrong AAD must fail authentication (returns false).
$bad = sodium_crypto_aead_aegis256_decrypt($ct, 'wrong-aad', $nonce, $key);
if ($bad !== false) {
    fwrite(STDERR, "decrypt under wrong AAD did not fail\n"); exit(1);
}

echo "ok ", strlen($ct), PHP_EOL;
PHP
