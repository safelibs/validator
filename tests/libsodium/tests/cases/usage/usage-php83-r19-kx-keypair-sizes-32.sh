#!/usr/bin/env bash
# @testcase: usage-php83-r19-kx-keypair-sizes-32
# @title: PHP sodium_crypto_kx_keypair components are 32-byte public and 32-byte secret keys
# @description: Calls sodium_crypto_kx_keypair() then sodium_crypto_kx_publickey() and sodium_crypto_kx_secretkey() on the result, asserts both are binary strings of exactly SODIUM_CRYPTO_KX_PUBLICKEYBYTES (32) and SODIUM_CRYPTO_KX_SECRETKEYBYTES (32) bytes respectively, and asserts the combined kx_keypair raw value has length SODIUM_CRYPTO_KX_KEYPAIRBYTES (64), exercising the libsodium kx key extraction surface.
# @timeout: 60
# @tags: usage, crypto, kx, keypair, php, r19
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$kp = sodium_crypto_kx_keypair();
$pk = sodium_crypto_kx_publickey($kp);
$sk = sodium_crypto_kx_secretkey($kp);
if (strlen($kp) !== SODIUM_CRYPTO_KX_KEYPAIRBYTES) { fwrite(STDERR, "kp_len=" . strlen($kp) . "\n"); exit(1); }
if (strlen($pk) !== SODIUM_CRYPTO_KX_PUBLICKEYBYTES) { fwrite(STDERR, "pk_len=" . strlen($pk) . "\n"); exit(1); }
if (strlen($sk) !== SODIUM_CRYPTO_KX_SECRETKEYBYTES) { fwrite(STDERR, "sk_len=" . strlen($sk) . "\n"); exit(1); }
if (SODIUM_CRYPTO_KX_PUBLICKEYBYTES !== 32) { fwrite(STDERR, "PK const not 32\n"); exit(1); }
if (SODIUM_CRYPTO_KX_SECRETKEYBYTES !== 32) { fwrite(STDERR, "SK const not 32\n"); exit(1); }
echo "ok kx sizes pk=", strlen($pk), " sk=", strlen($sk), " kp=", strlen($kp), PHP_EOL;
'
