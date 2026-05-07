#!/usr/bin/env bash
# @testcase: usage-php83-r15-generichash-explicit-length-32
# @title: PHP sodium_crypto_generichash with explicit length 32 returns a deterministic 32-byte digest
# @description: Calls sodium_crypto_generichash on a fixed payload with an explicit length argument of 32, asserts the result is a 32-byte string, asserts a second call on the same input yields byte-identical output (deterministic), and asserts changing the input changes the digest — exercising PHP's libsodium BLAKE2b binding.
# @timeout: 180
# @tags: usage, crypto, blake2b, generichash, php, r15
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$msg = "r15 php generichash payload";
$h1 = sodium_crypto_generichash($msg, "", 32);
if (!is_string($h1)) { fwrite(STDERR, "not string\n"); exit(1); }
if (strlen($h1) !== 32) { fwrite(STDERR, "len=" . strlen($h1) . "\n"); exit(1); }

// Determinism.
$h2 = sodium_crypto_generichash($msg, "", 32);
if ($h1 !== $h2) { fwrite(STDERR, "non-deterministic generichash\n"); exit(1); }

// Different input must produce a different digest.
$h3 = sodium_crypto_generichash($msg . "!", "", 32);
if ($h1 === $h3) { fwrite(STDERR, "digest collided across distinct inputs\n"); exit(1); }

echo "ok ", bin2hex($h1), PHP_EOL;
'
