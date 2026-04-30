#!/usr/bin/env bash
# @testcase: usage-php83-sodium-generichash-empty-kat
# @title: PHP sodium generichash empty-input known-answer
# @description: Computes sodium_crypto_generichash('') with the default 32-byte output and asserts the lowercase hex digest exactly matches the canonical libsodium / BLAKE2b-256 empty-input known-answer vector.
# @timeout: 180
# @tags: usage, crypto, hash, kat, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$digest = sodium_crypto_generichash('');
if (strlen($digest) !== SODIUM_CRYPTO_GENERICHASH_BYTES) {
    fwrite(STDERR, "default length mismatch\n"); exit(1);
}
$hex = sodium_bin2hex($digest);
$expected = '0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8';
if ($hex !== $expected) {
    fwrite(STDERR, "BLAKE2b-256 empty KAT mismatch: $hex\n"); exit(1);
}
echo $hex, PHP_EOL;
PHP
