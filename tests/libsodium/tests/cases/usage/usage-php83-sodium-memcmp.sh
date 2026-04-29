#!/usr/bin/env bash
# @testcase: usage-php83-sodium-memcmp
# @title: PHP sodium memcmp
# @description: Exercises php sodium memcmp through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-memcmp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
if (sodium_memcmp('abcd', 'abcd') !== 0) { exit(1); }
if (sodium_memcmp('abcd', 'abce') === 0) { exit(1); }
echo "memcmp\n";
PHP
