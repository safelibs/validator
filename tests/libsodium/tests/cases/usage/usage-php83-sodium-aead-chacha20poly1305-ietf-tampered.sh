#!/usr/bin/env bash
# @testcase: usage-php83-sodium-aead-chacha20poly1305-ietf-tampered
# @title: PHP sodium ChaCha20-Poly1305-IETF rejects tampered ciphertext
# @description: Encrypts a payload with sodium_crypto_aead_chacha20poly1305_ietf_encrypt under a fixed key, nonce, and AAD, then flips a byte inside the ciphertext body (not the tag) and asserts sodium_crypto_aead_chacha20poly1305_ietf_decrypt returns false. Repeats the check with a corrupted Poly1305 tag byte and a wrong key, confirming AEAD authentication catches each failure mode.
# @timeout: 180
# @tags: usage, crypto, aead, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$KEYBYTES = SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_KEYBYTES;
$NPUBBYTES = SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_NPUBBYTES;
$ABYTES = SODIUM_CRYPTO_AEAD_CHACHA20POLY1305_IETF_ABYTES;

$key = str_repeat("\x77", $KEYBYTES);
$nonce = str_repeat("\x11", $NPUBBYTES);
$aad = "validator-tampered-aad";
$plain = "chacha20poly1305 tamper payload of moderate length";

$cipher = sodium_crypto_aead_chacha20poly1305_ietf_encrypt($plain, $aad, $nonce, $key);
if ($cipher === false) { fwrite(STDERR, "encrypt failed\n"); exit(1); }
if (strlen($cipher) !== strlen($plain) + $ABYTES) { fwrite(STDERR, "len\n"); exit(2); }

$ok = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($cipher, $aad, $nonce, $key);
if ($ok !== $plain) { fwrite(STDERR, "baseline decrypt failed\n"); exit(3); }

// Flip a byte inside the ciphertext body.
$body = $cipher;
$body[3] = chr(ord($body[3]) ^ 0xFF);
$tampered_body = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($body, $aad, $nonce, $key);
if ($tampered_body !== false) { fwrite(STDERR, "body tamper accepted\n"); exit(4); }

// Flip a byte inside the trailing Poly1305 tag.
$tag = $cipher;
$tag[strlen($tag) - 1] = chr(ord($tag[strlen($tag) - 1]) ^ 0xFF);
$tampered_tag = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($tag, $aad, $nonce, $key);
if ($tampered_tag !== false) { fwrite(STDERR, "tag tamper accepted\n"); exit(5); }

// Wrong key.
$wrong_key = str_repeat("\x99", $KEYBYTES);
$wrong = sodium_crypto_aead_chacha20poly1305_ietf_decrypt($cipher, $aad, $nonce, $wrong_key);
if ($wrong !== false) { fwrite(STDERR, "wrong-key decrypt accepted\n"); exit(6); }

echo "ok ", strlen($cipher), PHP_EOL;
PHP
