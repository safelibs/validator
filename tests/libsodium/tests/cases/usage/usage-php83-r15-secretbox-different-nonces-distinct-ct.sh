#!/usr/bin/env bash
# @testcase: usage-php83-r15-secretbox-different-nonces-distinct-ct
# @title: PHP sodium_crypto_secretbox with the same key but different nonces yields distinct ciphertexts
# @description: Encrypts the same plaintext twice with sodium_crypto_secretbox under a fixed 32-byte key but two distinct 24-byte nonces, asserts both ciphertexts are exactly len(plaintext)+SODIUM_CRYPTO_SECRETBOX_MACBYTES (16) long, asserts the two ciphertexts differ, and asserts each one decrypts under its matching nonce back to the original plaintext.
# @timeout: 180
# @tags: usage, crypto, secretbox, nonce, php, r15
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$key = str_repeat("\x15", SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$nonce_a = str_repeat("\x01", SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$nonce_b = str_repeat("\x02", SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$plain = "r15 php secretbox payload";

$ct_a = sodium_crypto_secretbox($plain, $nonce_a, $key);
$ct_b = sodium_crypto_secretbox($plain, $nonce_b, $key);

$expected_len = strlen($plain) + SODIUM_CRYPTO_SECRETBOX_MACBYTES;
if (strlen($ct_a) !== $expected_len) { fwrite(STDERR, "ct_a len " . strlen($ct_a) . "\n"); exit(1); }
if (strlen($ct_b) !== $expected_len) { fwrite(STDERR, "ct_b len " . strlen($ct_b) . "\n"); exit(1); }

if ($ct_a === $ct_b) { fwrite(STDERR, "distinct nonces produced identical ciphertext\n"); exit(1); }

$pt_a = sodium_crypto_secretbox_open($ct_a, $nonce_a, $key);
$pt_b = sodium_crypto_secretbox_open($ct_b, $nonce_b, $key);
if ($pt_a !== $plain) { fwrite(STDERR, "ct_a roundtrip mismatch\n"); exit(1); }
if ($pt_b !== $plain) { fwrite(STDERR, "ct_b roundtrip mismatch\n"); exit(1); }

echo "ok ", strlen($ct_a), PHP_EOL;
'
