#!/usr/bin/env bash
# @testcase: usage-php83-r21-crypto-aead-xchacha20poly1305-ietf-roundtrip
# @title: PHP sodium_crypto_aead_xchacha20poly1305_ietf_encrypt/_decrypt round-trips message with AAD
# @description: Generates a 32-byte key and 24-byte nonce, calls sodium_crypto_aead_xchacha20poly1305_ietf_encrypt with non-empty additional data, then decrypts with sodium_crypto_aead_xchacha20poly1305_ietf_decrypt and asserts the decrypted plaintext equals the original, exercising libsodium's IETF XChaCha20-Poly1305 AEAD path.
# @timeout: 60
# @tags: usage, sodium, aead, xchacha20poly1305, php, r21
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$k = sodium_crypto_aead_xchacha20poly1305_ietf_keygen();
if (strlen($k) !== SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES) { fwrite(STDERR, "key_len=".strlen($k)."\n"); exit(1); }
$n = random_bytes(SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES);
if (strlen($n) !== 24) { fwrite(STDERR, "nonce_len=".strlen($n)."\n"); exit(1); }
$pt = "round-trip r21 payload";
$ad = "header:r21";
$ct = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt($pt, $ad, $n, $k);
$rt = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($ct, $ad, $n, $k);
if ($rt !== $pt) { fwrite(STDERR, "rt mismatch\n"); exit(1); }
echo "ok aead_xchacha pt_len=", strlen($pt), PHP_EOL;
'
