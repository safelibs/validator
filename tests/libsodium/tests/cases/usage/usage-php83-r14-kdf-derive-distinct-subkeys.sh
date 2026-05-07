#!/usr/bin/env bash
# @testcase: usage-php83-r14-kdf-derive-distinct-subkeys
# @title: PHP sodium_crypto_kdf_derive_from_key derives distinct subkeys per integer id
# @description: Generates a master key with sodium_crypto_kdf_keygen, derives two 32-byte subkeys with subkey ids 1 and 2 under the same context string, asserts each subkey has the requested length, asserts the two subkeys differ, and asserts that re-deriving subkey id 1 reproduces the same bytes (deterministic for fixed inputs).
# @timeout: 180
# @tags: usage, crypto, kdf, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$master = sodium_crypto_kdf_keygen();
if (strlen($master) !== SODIUM_CRYPTO_KDF_KEYBYTES) {
    fwrite(STDERR, "master key length mismatch\n"); exit(1);
}

$ctx = "r14ctx00";  // exactly SODIUM_CRYPTO_KDF_CONTEXTBYTES (8)
if (strlen($ctx) !== SODIUM_CRYPTO_KDF_CONTEXTBYTES) {
    fwrite(STDERR, "context length mismatch\n"); exit(1);
}

$len = 32;
$sub1 = sodium_crypto_kdf_derive_from_key($len, 1, $ctx, $master);
$sub2 = sodium_crypto_kdf_derive_from_key($len, 2, $ctx, $master);

if (strlen($sub1) !== $len || strlen($sub2) !== $len) {
    fwrite(STDERR, "subkey length mismatch\n"); exit(1);
}
if ($sub1 === $sub2) {
    fwrite(STDERR, "distinct subkey ids produced identical bytes\n"); exit(1);
}

$sub1_again = sodium_crypto_kdf_derive_from_key($len, 1, $ctx, $master);
if ($sub1_again !== $sub1) {
    fwrite(STDERR, "kdf not deterministic for fixed inputs\n"); exit(1);
}
echo "ok\n";
'
