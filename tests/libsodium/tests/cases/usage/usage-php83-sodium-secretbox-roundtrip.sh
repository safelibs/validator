#!/usr/bin/env bash
# @testcase: usage-php83-sodium-secretbox-roundtrip
# @title: PHP sodium secretbox round trip
# @description: Exercises php sodium secretbox round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-secretbox-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_SECRETBOX_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
$cipher = sodium_crypto_secretbox('secret payload', $nonce, $key);
$plain = sodium_crypto_secretbox_open($cipher, $nonce, $key);
if ($plain !== 'secret payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
