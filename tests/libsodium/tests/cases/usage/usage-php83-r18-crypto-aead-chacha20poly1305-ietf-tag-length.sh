#!/usr/bin/env bash
# @testcase: usage-php83-r18-crypto-aead-chacha20poly1305-ietf-tag-length
# @title: PHP sodium_crypto_aead_chacha20poly1305_ietf_encrypt ciphertext is plaintext+16 bytes
# @description: Encrypts a fixed payload via sodium_crypto_aead_chacha20poly1305_ietf_encrypt under a random 32-byte key, 12-byte IETF nonce, and fixed AAD, asserts the ciphertext length equals plaintext length + SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_ABYTES (16) and that decryption with the same key/nonce/aad returns the original plaintext byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, aead, chacha20poly1305, php, r18
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$key   = random_bytes(SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_NPUBBYTES);
$aad   = "r18-php-aad-context";
$msg   = "r18 php chacha20poly1305 ietf payload";
$ct    = sodium_crypto_aead_chacha20poly1305_ietf_encrypt($msg, $aad, $nonce, $key);
$expected = strlen($msg) + SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_ABYTES;
if (strlen($ct) !== $expected) {
    fwrite(STDERR, "ct_len=" . strlen($ct) . " expected=" . $expected . "\n");
    exit(1);
}
$pt = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($ct, $aad, $nonce, $key);
if ($pt !== $msg) { fwrite(STDERR, "pt mismatch\n"); exit(1); }
echo "ok aead ct=", strlen($ct), PHP_EOL;
'
