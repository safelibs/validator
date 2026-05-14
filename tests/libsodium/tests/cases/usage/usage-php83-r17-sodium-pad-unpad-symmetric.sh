#!/usr/bin/env bash
# @testcase: usage-php83-r17-sodium-pad-unpad-symmetric
# @title: PHP sodium_pad followed by sodium_unpad restores the original buffer
# @description: Builds a 13-byte payload, pads to a 16-byte block boundary with sodium_pad, asserts the padded length is a positive multiple of 16 strictly greater than 13, then calls sodium_unpad with the same block size and asserts the recovered buffer equals the original payload byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, pad, php, r17
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$payload = "r17 php pad17";
$block = 16;
$padded = sodium_pad($payload, $block);
if (strlen($padded) <= strlen($payload)) { fwrite(STDERR, "padded len " . strlen($padded) . "\n"); exit(1); }
if ((strlen($padded) % $block) !== 0)    { fwrite(STDERR, "not multiple of $block: " . strlen($padded) . "\n"); exit(1); }
$unpadded = sodium_unpad($padded, $block);
if ($unpadded !== $payload) { fwrite(STDERR, "unpad mismatch\n"); exit(1); }
echo "ok padded=", strlen($padded), PHP_EOL;
'
