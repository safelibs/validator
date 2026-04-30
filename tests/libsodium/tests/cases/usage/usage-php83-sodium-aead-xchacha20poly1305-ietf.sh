#!/usr/bin/env bash
# @testcase: usage-php83-sodium-aead-xchacha20poly1305-ietf
# @title: PHP sodium XChaCha20-Poly1305-IETF AEAD deterministic KAT
# @description: Encrypts a fixed payload with sodium_crypto_aead_xchacha20poly1305_ietf_encrypt under a deterministic 32-byte key, 24-byte nonce, and AAD; asserts ciphertext length is plaintext + ABYTES, that the same inputs produce the same ciphertext, that decryption recovers the original plaintext, and that decryption with a flipped AAD returns false.
# @timeout: 180
# @tags: usage, crypto, aead, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$KEYBYTES = SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES;
$NPUBBYTES = SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES;
$ABYTES = SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_ABYTES;

if ($KEYBYTES !== 32) { fwrite(STDERR, "unexpected key bytes: $KEYBYTES\n"); exit(10); }
if ($NPUBBYTES !== 24) { fwrite(STDERR, "unexpected nonce bytes: $NPUBBYTES\n"); exit(11); }

$key = str_repeat("\x5a", $KEYBYTES);
$nonce = str_repeat("\xa5", $NPUBBYTES);
$aad = "validator-xchacha-aad";
$plain = "xchacha20poly1305 ietf payload";

$cipher = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt($plain, $aad, $nonce, $key);
if ($cipher === false) { exit(1); }
if (strlen($cipher) !== strlen($plain) + $ABYTES) { exit(2); }

$cipher2 = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt($plain, $aad, $nonce, $key);
if ($cipher !== $cipher2) { exit(3); }

$decoded = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($cipher, $aad, $nonce, $key);
if ($decoded !== $plain) { exit(4); }

$tampered = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($cipher, "validator-bad-aad", $nonce, $key);
if ($tampered !== false) { exit(5); }

echo bin2hex(substr($cipher, 0, 8)), PHP_EOL;
PHP
