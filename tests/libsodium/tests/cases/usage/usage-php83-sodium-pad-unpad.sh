#!/usr/bin/env bash
# @testcase: usage-php83-sodium-pad-unpad
# @title: PHP sodium pad and unpad
# @description: Pads and unpads a payload with PHP sodium and verifies the unpadded text matches the original bytes.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-pad-unpad"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$padded = sodium_pad('pad payload', 16);
$plain = sodium_unpad($padded, 16);
if ($plain !== 'pad payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
