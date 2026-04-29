#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sign-seed-keypair
# @title: PHP sodium sign seed keypair
# @description: Exercises php sodium sign seed keypair through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-sign-seed-keypair"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$seed = str_repeat("\x01", SODIUM_CRYPTO_SIGN_SEEDBYTES);
$keypair = sodium_crypto_sign_seed_keypair($seed);
$public = sodium_crypto_sign_publickey($keypair);
if (strlen($public) !== SODIUM_CRYPTO_SIGN_PUBLICKEYBYTES) { exit(1); }
echo strlen($public), PHP_EOL;
PHP
