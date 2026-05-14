#!/usr/bin/env bash
# @testcase: usage-php83-r18-generichash-distinct-keys-distinct-outputs
# @title: PHP sodium_crypto_generichash with distinct keys produces distinct outputs for the same message
# @description: Computes sodium_crypto_generichash(msg, key) for a fixed payload under two independently generated 32-byte keys using the default 32-byte digest length, asserts both outputs are 32-byte binary strings, asserts the two outputs differ from each other, and asserts a third call with the first key reproduces the first output (keyed determinism).
# @timeout: 60
# @tags: usage, crypto, generichash, mac, php, r18
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$msg = "r18 php generichash keyed payload";
$k1  = random_bytes(SODIUM_CRYPTO_GENERICHASH_KEYBYTES);
$k2  = random_bytes(SODIUM_CRYPTO_GENERICHASH_KEYBYTES);
$h1  = sodium_crypto_generichash($msg, $k1);
$h2  = sodium_crypto_generichash($msg, $k2);
$h1b = sodium_crypto_generichash($msg, $k1);
if (strlen($h1) !== 32) { fwrite(STDERR, "len h1=" . strlen($h1) . "\n"); exit(1); }
if (strlen($h2) !== 32) { fwrite(STDERR, "len h2=" . strlen($h2) . "\n"); exit(1); }
if ($h1 === $h2)        { fwrite(STDERR, "distinct keys collided\n"); exit(1); }
if ($h1 !== $h1b)       { fwrite(STDERR, "same key not deterministic\n"); exit(1); }
echo "ok keyed_generichash len=", strlen($h1), PHP_EOL;
'
