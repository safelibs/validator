#!/usr/bin/env bash
# @testcase: usage-php83-r20-shorthash-keygen-length-and-distinct
# @title: PHP sodium_crypto_shorthash_keygen returns 16-byte keys and two calls produce distinct keys
# @description: Calls sodium_crypto_shorthash_keygen twice in the same PHP process, asserts each return value has strlen equal to SODIUM_CRYPTO_SHORTHASH_KEYBYTES (16), and asserts the two keys are not equal byte-for-byte, confirming libsodium-backed SipHash key generation is correctly sized and consumes fresh randomness on each invocation.
# @timeout: 60
# @tags: usage, sodium, shorthash, keygen, php, r20
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$a = sodium_crypto_shorthash_keygen();
$b = sodium_crypto_shorthash_keygen();
if (strlen($a) !== SODIUM_CRYPTO_SHORTHASH_KEYBYTES) {
    fwrite(STDERR, "a_len=" . strlen($a) . "\n"); exit(1);
}
if (strlen($b) !== SODIUM_CRYPTO_SHORTHASH_KEYBYTES) {
    fwrite(STDERR, "b_len=" . strlen($b) . "\n"); exit(1);
}
if (SODIUM_CRYPTO_SHORTHASH_KEYBYTES !== 16) {
    fwrite(STDERR, "key_const=" . SODIUM_CRYPTO_SHORTHASH_KEYBYTES . "\n"); exit(1);
}
if ($a === $b) {
    fwrite(STDERR, "keys collided\n"); exit(1);
}
echo "ok keygen_len=", strlen($a), PHP_EOL;
'
