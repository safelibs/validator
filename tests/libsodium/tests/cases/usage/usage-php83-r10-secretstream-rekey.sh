#!/usr/bin/env bash
# @testcase: usage-php83-r10-secretstream-rekey
# @title: PHP sodium_crypto_secretstream rekey continues a stream
# @description: Pushes two messages through sodium_crypto_secretstream_xchacha20poly1305_push, calls sodium_crypto_secretstream_xchacha20poly1305_rekey on both push and pull state between them, and asserts the pull side recovers both plaintexts in order with the matching tags.
# @timeout: 180
# @tags: usage, crypto, php, secretstream
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
$key = sodium_crypto_secretstream_xchacha20poly1305_keygen();
[$header, $push_state] = sodium_crypto_secretstream_xchacha20poly1305_init_push($key);

$msg1 = "secretstream r10 part one";
$msg2 = "secretstream r10 part two";

$ct1 = sodium_crypto_secretstream_xchacha20poly1305_push(
    $push_state, $msg1, '', SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_MESSAGE
);

sodium_crypto_secretstream_xchacha20poly1305_rekey($push_state);

$ct2 = sodium_crypto_secretstream_xchacha20poly1305_push(
    $push_state, $msg2, '', SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_FINAL
);

$pull_state = sodium_crypto_secretstream_xchacha20poly1305_init_pull($header, $key);

[$pt1, $tag1] = sodium_crypto_secretstream_xchacha20poly1305_pull($pull_state, $ct1);
if ($pt1 !== $msg1 || $tag1 !== SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_MESSAGE) {
    fwrite(STDERR, "first pull mismatch\n"); exit(1);
}

sodium_crypto_secretstream_xchacha20poly1305_rekey($pull_state);

[$pt2, $tag2] = sodium_crypto_secretstream_xchacha20poly1305_pull($pull_state, $ct2);
if ($pt2 !== $msg2 || $tag2 !== SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_FINAL) {
    fwrite(STDERR, "second pull mismatch\n"); exit(2);
}
echo "ok\n";
PHP
