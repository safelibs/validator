#!/usr/bin/env bash
# @testcase: usage-php83-sodium-secretstream-push-pull
# @title: PHP sodium secretstream xchacha20poly1305 push/pull
# @description: Drives sodium_crypto_secretstream_xchacha20poly1305_init_push and init_pull through three messages with intermediate MESSAGE tags and a final FINAL tag, asserts the header is exactly SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_HEADERBYTES, every chunk decrypts byte-for-byte, and the last observed tag equals FINAL.
# @timeout: 180
# @tags: usage, crypto, secretstream, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = sodium_crypto_secretstream_xchacha20poly1305_keygen();
if (strlen($key) !== SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_KEYBYTES) {
    fwrite(STDERR, "key bytes mismatch\n"); exit(1);
}

[$push_state, $header] = (function () use ($key) {
    $st = sodium_crypto_secretstream_xchacha20poly1305_init_push($key);
    return [$st[0], $st[1]];
})();
if (strlen($header) !== SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_HEADERBYTES) {
    fwrite(STDERR, "header bytes mismatch\n"); exit(1);
}

$messages = ['first chunk', 'second chunk', 'final chunk'];
$ad = 'validator-ad';
$ciphertexts = [];
$last = count($messages) - 1;
foreach ($messages as $i => $m) {
    $tag = ($i === $last)
        ? SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_FINAL
        : SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_MESSAGE;
    $ct = sodium_crypto_secretstream_xchacha20poly1305_push($push_state, $m, $ad, $tag);
    if (strlen($ct) !== strlen($m) + SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_ABYTES) {
        fwrite(STDERR, "push len mismatch at $i\n"); exit(1);
    }
    $ciphertexts[] = $ct;
}

$pull_state = sodium_crypto_secretstream_xchacha20poly1305_init_pull($header, $key);

$last_tag = null;
$recovered = [];
foreach ($ciphertexts as $i => $ct) {
    $r = sodium_crypto_secretstream_xchacha20poly1305_pull($pull_state, $ct, $ad);
    if ($r === false) { fwrite(STDERR, "pull failed at $i\n"); exit(1); }
    [$pt, $last_tag] = [$r[0], $r[1]];
    $recovered[] = $pt;
}

if ($recovered !== $messages) { fwrite(STDERR, "decrypted mismatch\n"); exit(1); }
if ($last_tag !== SODIUM_CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_TAG_FINAL) {
    fwrite(STDERR, "final tag missing\n"); exit(1);
}
echo "ok ", count($recovered), PHP_EOL;
PHP
