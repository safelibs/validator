#!/usr/bin/env bash
# @testcase: usage-php83-r12-crypto-box-keypair-roundtrip
# @title: PHP sodium_crypto_box round-trips with explicit keypair handles
# @description: Generates two sodium_crypto_box keypairs, derives the public/secret components, encrypts a payload from sender to receiver with a deterministic 24-byte nonce, decrypts it back, and asserts the recovered plaintext matches the original.
# @timeout: 60
# @tags: usage, crypto, box, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$kp_s = sodium_crypto_box_keypair();
$kp_r = sodium_crypto_box_keypair();
$sk_s = sodium_crypto_box_secretkey($kp_s);
$pk_r = sodium_crypto_box_publickey($kp_r);
$sk_r = sodium_crypto_box_secretkey($kp_r);
$pk_s = sodium_crypto_box_publickey($kp_s);

$nonce = str_repeat("\x09", SODIUM_CRYPTO_BOX_NONCEBYTES);
$plain = "php r12 crypto_box payload";

$send_kp = sodium_crypto_box_keypair_from_secretkey_and_publickey($sk_s, $pk_r);
$recv_kp = sodium_crypto_box_keypair_from_secretkey_and_publickey($sk_r, $pk_s);

$ct = sodium_crypto_box($plain, $nonce, $send_kp);
if ($ct === $plain) { fwrite(STDERR, "ciphertext == plaintext\n"); exit(1); }

$pt = sodium_crypto_box_open($ct, $nonce, $recv_kp);
if ($pt !== $plain) { fwrite(STDERR, "round-trip mismatch\n"); exit(1); }
echo "ok\n";
'
