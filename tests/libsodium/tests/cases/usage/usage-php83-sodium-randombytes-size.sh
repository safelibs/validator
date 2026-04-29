#!/usr/bin/env bash
# @testcase: usage-php83-sodium-randombytes-size
# @title: PHP sodium random bytes size
# @description: Exercises php sodium random bytes size through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-randombytes-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$value = random_bytes(18);
if (strlen($value) !== 18) { exit(1); }
echo strlen($value), PHP_EOL;
PHP
