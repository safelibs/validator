#!/usr/bin/env bash
# @testcase: usage-php83-sodium-generichash-state
# @title: PHP sodium generichash state
# @description: Exercises php sodium generichash state through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-generichash-state"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$state = sodium_crypto_generichash_init('', 16);
sodium_crypto_generichash_update($state, 'part-one');
sodium_crypto_generichash_update($state, '-part-two');
$hash = sodium_crypto_generichash_final($state, 16);
if (strlen($hash) !== 16) { exit(1); }
echo sodium_bin2hex($hash), PHP_EOL;
PHP
