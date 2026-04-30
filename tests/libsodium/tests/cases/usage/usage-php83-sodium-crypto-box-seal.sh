#!/usr/bin/env bash
# @testcase: usage-php83-sodium-crypto-box-seal
# @title: PHP sodium crypto_box_seal one-way anonymous encryption
# @description: Generates a recipient curve25519 keypair, encrypts a plaintext with sodium_crypto_box_seal using only the recipient public key, asserts the sealed ciphertext is exactly plaintext + SODIUM_CRYPTO_BOX_SEALBYTES long, opens it with sodium_crypto_box_seal_open using the recipient keypair, and asserts that opening with a different unrelated keypair returns false.
# @timeout: 180
# @tags: usage, crypto, php, sealed-box
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$recipient = sodium_crypto_box_keypair();
$recipient_pub = sodium_crypto_box_publickey($recipient);
if (strlen($recipient_pub) !== SODIUM_CRYPTO_BOX_PUBLICKEYBYTES) { exit(10); }

$plain = "anonymous sealed-box payload";
$sealed = sodium_crypto_box_seal($plain, $recipient_pub);
if ($sealed === false) { exit(1); }
if (strlen($sealed) !== strlen($plain) + SODIUM_CRYPTO_BOX_SEALBYTES) { exit(2); }
if ($sealed === $plain) { exit(3); }

$opened = sodium_crypto_box_seal_open($sealed, $recipient);
if ($opened !== $plain) { exit(4); }

// Re-sealing the same plaintext for the same recipient must produce a fresh ephemeral key, so two seals should not collide.
$sealed2 = sodium_crypto_box_seal($plain, $recipient_pub);
if ($sealed === $sealed2) { exit(5); }

// An unrelated recipient cannot open the ciphertext.
$other = sodium_crypto_box_keypair();
$wrong = sodium_crypto_box_seal_open($sealed, $other);
if ($wrong !== false) { exit(6); }

echo bin2hex(substr($sealed, 0, 8)), PHP_EOL;
PHP
