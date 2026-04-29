#!/usr/bin/env bash
# @testcase: usage-php83-sodium-generichash-length
# @title: php83 sodium generichash length
# @description: Computes a generic hash through PHP sodium_crypto_generichash and verifies the digest matches the GENERICHASH_BYTES constant.
# @timeout: 180
# @tags: usage, php, hash
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-generichash-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$h = sodium_crypto_generichash('payload');
if (strlen($h) !== SODIUM_CRYPTO_GENERICHASH_BYTES) { exit(1); }
echo strlen($h), PHP_EOL;
PHP
