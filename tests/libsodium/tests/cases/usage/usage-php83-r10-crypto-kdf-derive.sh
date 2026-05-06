#!/usr/bin/env bash
# @testcase: usage-php83-r10-crypto-kdf-derive
# @title: PHP sodium_crypto_kdf_derive_from_key produces distinct subkeys per id
# @description: Generates a master key with sodium_crypto_kdf_keygen, derives two 32-byte subkeys with sodium_crypto_kdf_derive_from_key under the same context but different subkey ids, and asserts the two subkeys differ while a re-derivation with the same id reproduces the same bytes.
# @timeout: 180
# @tags: usage, crypto, php, kdf
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
$master = sodium_crypto_kdf_keygen();
if (strlen($master) !== SODIUM_CRYPTO_KDF_KEYBYTES) {
    fwrite(STDERR, "bad master length\n"); exit(1);
}
$ctx = "valr10ct"; // 8-byte context per libsodium
$sub1 = sodium_crypto_kdf_derive_from_key(32, 1, $ctx, $master);
$sub2 = sodium_crypto_kdf_derive_from_key(32, 2, $ctx, $master);
$sub1_again = sodium_crypto_kdf_derive_from_key(32, 1, $ctx, $master);

if (strlen($sub1) !== 32 || strlen($sub2) !== 32) {
    fwrite(STDERR, "wrong subkey length\n"); exit(2);
}
if ($sub1 === $sub2) {
    fwrite(STDERR, "different ids produced same subkey\n"); exit(3);
}
if ($sub1 !== $sub1_again) {
    fwrite(STDERR, "kdf is non-deterministic for fixed inputs\n"); exit(4);
}
echo "ok\n";
PHP
