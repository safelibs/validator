#!/usr/bin/env bash
# @testcase: usage-php83-sodium-pwhash
# @title: PHP sodium password hash
# @description: Creates and verifies a password hash through PHP sodium bindings.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-pwhash"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$hash = sodium_crypto_pwhash_str('password', SODIUM_CRYPTO_PWHASH_OPSLIMIT_INTERACTIVE, SODIUM_CRYPTO_PWHASH_MEMLIMIT_INTERACTIVE);
if (!sodium_crypto_pwhash_str_verify($hash, 'password')) { exit(1); }
echo "password verified\n";
PHP
