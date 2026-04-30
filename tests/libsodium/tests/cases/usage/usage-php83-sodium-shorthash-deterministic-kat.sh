#!/usr/bin/env bash
# @testcase: usage-php83-sodium-shorthash-deterministic-kat
# @title: PHP sodium_crypto_shorthash determinism KAT
# @description: Computes sodium_crypto_shorthash on a fixed message with an all-zero 16-byte SipHash key, asserts the output is exactly SODIUM_CRYPTO_SHORTHASH_BYTES (8) bytes, that two calls with identical inputs produce identical bytes, and that changing one byte of the message produces a different digest.
# @timeout: 180
# @tags: usage, crypto, shorthash, kat, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = str_repeat("\x00", SODIUM_CRYPTO_SHORTHASH_KEYBYTES);
if (strlen($key) !== 16) { fwrite(STDERR, "key size wrong\n"); exit(1); }

$msg = 'validator-shorthash';
$h1 = sodium_crypto_shorthash($msg, $key);
$h2 = sodium_crypto_shorthash($msg, $key);
if (strlen($h1) !== SODIUM_CRYPTO_SHORTHASH_BYTES) { fwrite(STDERR, "size mismatch\n"); exit(1); }
if (SODIUM_CRYPTO_SHORTHASH_BYTES !== 8)            { fwrite(STDERR, "constant changed\n"); exit(1); }
if (!hash_equals($h1, $h2))                          { fwrite(STDERR, "non-deterministic\n"); exit(1); }

$h3 = sodium_crypto_shorthash($msg . 'x', $key);
if (hash_equals($h1, $h3)) { fwrite(STDERR, "different inputs collided\n"); exit(1); }

// Empty input under all-zero key must still yield 8 bytes.
$h_empty = sodium_crypto_shorthash('', $key);
if (strlen($h_empty) !== SODIUM_CRYPTO_SHORTHASH_BYTES) { fwrite(STDERR, "empty size wrong\n"); exit(1); }

echo sodium_bin2hex($h1), PHP_EOL;
PHP
