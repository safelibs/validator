#!/usr/bin/env bash
# @testcase: usage-php83-r11-crypto-shorthash-keyed
# @title: PHP sodium_crypto_shorthash is deterministic per key and key-sensitive
# @description: Computes sodium_crypto_shorthash on the same input with two distinct 16-byte keys, asserts the same key reproduces the identical 8-byte SipHash digest, and asserts a different key produces a different digest, exercising the keyed shorthash primitive.
# @timeout: 180
# @tags: usage, crypto, php, shorthash
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
$msg = "libsodium r11 shorthash payload";
$keyA = str_repeat("\x11", SODIUM_CRYPTO_SHORTHASH_KEYBYTES);
$keyB = str_repeat("\x22", SODIUM_CRYPTO_SHORTHASH_KEYBYTES);

$a1 = sodium_crypto_shorthash($msg, $keyA);
$a2 = sodium_crypto_shorthash($msg, $keyA);
$b1 = sodium_crypto_shorthash($msg, $keyB);

if (strlen($a1) !== SODIUM_CRYPTO_SHORTHASH_BYTES) {
    fwrite(STDERR, "wrong digest length\n"); exit(1);
}
if ($a1 !== $a2) {
    fwrite(STDERR, "shorthash non-deterministic for same key\n"); exit(2);
}
if ($a1 === $b1) {
    fwrite(STDERR, "shorthash digest unchanged across keys\n"); exit(3);
}
echo "ok\n";
PHP
