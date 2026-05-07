#!/usr/bin/env bash
# @testcase: usage-php83-r14-pwhash-str-verify-rejects-wrong
# @title: PHP sodium_crypto_pwhash_str_verify accepts the matching password and rejects a wrong one
# @description: Hashes a password with sodium_crypto_pwhash_str at INTERACTIVE ops/mem limits, asserts the resulting hash is a non-empty string starting with $argon2id$, calls sodium_crypto_pwhash_str_verify which must return true for the matching password and false for a different password.
# @timeout: 180
# @tags: usage, crypto, pwhash, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$pw = "r14 php pwhash payload";
$hash = sodium_crypto_pwhash_str(
    $pw,
    SODIUM_CRYPTO_PWHASH_OPSLIMIT_INTERACTIVE,
    SODIUM_CRYPTO_PWHASH_MEMLIMIT_INTERACTIVE
);
if (!is_string($hash) || $hash === "") { fwrite(STDERR, "empty hash\n"); exit(1); }
if (strpos($hash, "\$argon2id\$") !== 0) {
    fwrite(STDERR, "unexpected hash prefix: " . substr($hash, 0, 16) . "\n");
    exit(1);
}

if (sodium_crypto_pwhash_str_verify($hash, $pw) !== true) {
    fwrite(STDERR, "matching password rejected\n"); exit(1);
}
if (sodium_crypto_pwhash_str_verify($hash, "r14 different password") !== false) {
    fwrite(STDERR, "wrong password accepted\n"); exit(1);
}
echo "ok\n";
'
