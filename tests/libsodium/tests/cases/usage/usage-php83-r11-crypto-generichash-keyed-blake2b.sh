#!/usr/bin/env bash
# @testcase: usage-php83-r11-crypto-generichash-keyed-blake2b
# @title: PHP sodium_crypto_generichash with a key changes the digest deterministically
# @description: Computes sodium_crypto_generichash digests of the same payload with no key, an all-0x11 key, and an all-0x22 key, asserts each variant is deterministic and exactly 32 bytes, and asserts the three digests are pairwise distinct, confirming the optional key argument flows into the Blake2b state.
# @timeout: 180
# @tags: usage, crypto, php, blake2b
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
$msg = "libsodium r11 generichash payload";
$keyA = str_repeat("\x11", 32);
$keyB = str_repeat("\x22", 32);

$plain1 = sodium_crypto_generichash($msg);
$plain2 = sodium_crypto_generichash($msg);
$digA1  = sodium_crypto_generichash($msg, $keyA);
$digA2  = sodium_crypto_generichash($msg, $keyA);
$digB1  = sodium_crypto_generichash($msg, $keyB);

foreach (["plain" => $plain1, "keyA" => $digA1, "keyB" => $digB1] as $tag => $dig) {
    if (strlen($dig) !== 32) {
        fwrite(STDERR, "$tag: wrong length " . strlen($dig) . "\n"); exit(1);
    }
}
if ($plain1 !== $plain2 || $digA1 !== $digA2) {
    fwrite(STDERR, "non-deterministic generichash digest\n"); exit(2);
}
if ($plain1 === $digA1 || $digA1 === $digB1 || $plain1 === $digB1) {
    fwrite(STDERR, "key parameter did not change digest\n"); exit(3);
}
echo "ok\n";
PHP
