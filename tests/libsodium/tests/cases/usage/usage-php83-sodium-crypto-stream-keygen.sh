#!/usr/bin/env bash
# @testcase: usage-php83-sodium-crypto-stream-keygen
# @title: PHP sodium crypto_stream_xchacha20 keystream length
# @description: Generates a 32-byte XChaCha20 key with sodium_crypto_stream_xchacha20_keygen, derives a 64-byte keystream with sodium_crypto_stream_xchacha20 under a 24-byte nonce, asserts the keystream length matches the requested size and is non-zero, and confirms re-running with the same key+nonce produces the same keystream while changing the nonce yields a different keystream. Exercises PHP's stream cipher binding without authentication.
# @timeout: 180
# @tags: usage, crypto, stream, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = sodium_crypto_stream_xchacha20_keygen();
if (strlen($key) !== SODIUM_CRYPTO_STREAM_XCHACHA20_KEYBYTES) {
    fwrite(STDERR, "key len mismatch: ".strlen($key)."\n"); exit(1);
}
if (strlen($key) !== 32) { fwrite(STDERR, "expected 32-byte key\n"); exit(2); }

$nonce = str_repeat("\x11", SODIUM_CRYPTO_STREAM_XCHACHA20_NONCEBYTES);
$ks_a = sodium_crypto_stream_xchacha20(64, $nonce, $key);
if (strlen($ks_a) !== 64) { fwrite(STDERR, "ks len mismatch\n"); exit(3); }
if ($ks_a === str_repeat("\x00", 64)) { fwrite(STDERR, "all-zero keystream\n"); exit(4); }

$ks_b = sodium_crypto_stream_xchacha20(64, $nonce, $key);
if ($ks_a !== $ks_b) { fwrite(STDERR, "keystream not deterministic\n"); exit(5); }

$nonce_other = str_repeat("\x22", SODIUM_CRYPTO_STREAM_XCHACHA20_NONCEBYTES);
$ks_c = sodium_crypto_stream_xchacha20(64, $nonce_other, $key);
if ($ks_c === $ks_a) { fwrite(STDERR, "nonce change produced identical keystream\n"); exit(6); }

echo "ok ", strlen($ks_a), PHP_EOL;
PHP
