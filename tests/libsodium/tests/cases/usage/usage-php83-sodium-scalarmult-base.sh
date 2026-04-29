#!/usr/bin/env bash
# @testcase: usage-php83-sodium-scalarmult-base
# @title: PHP sodium scalarmult base
# @description: Derives a Curve25519 public point from a random scalar with PHP sodium and verifies the output length.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-scalarmult-base"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$scalar = random_bytes(SODIUM_CRYPTO_SCALARMULT_SCALARBYTES);
$point = sodium_crypto_scalarmult_base($scalar);
if (strlen($point) !== SODIUM_CRYPTO_SCALARMULT_BYTES) { exit(1); }
echo strlen($point), PHP_EOL;
PHP
