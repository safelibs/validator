#!/usr/bin/env bash
# @testcase: usage-php83-r16-bin2hex-hex2bin-roundtrip
# @title: PHP sodium_bin2hex and sodium_hex2bin roundtrip a 32-byte binary payload
# @description: Generates 32 random bytes via random_bytes, encodes them with sodium_bin2hex, asserts the hex string is 64 lowercase characters, decodes via sodium_hex2bin and asserts the recovered bytes equal the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, bin2hex, php, r16
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$bin = random_bytes(32);
$hex = sodium_bin2hex($bin);
if (!is_string($hex)) { fwrite(STDERR, "hex not string\n"); exit(1); }
if (strlen($hex) !== 64) { fwrite(STDERR, "hex len=" . strlen($hex) . "\n"); exit(1); }
if ($hex !== strtolower($hex)) { fwrite(STDERR, "hex not lowercase\n"); exit(1); }
if (!ctype_xdigit($hex)) { fwrite(STDERR, "hex contains non-hex chars\n"); exit(1); }
$decoded = sodium_hex2bin($hex);
if ($decoded !== $bin) { fwrite(STDERR, "roundtrip mismatch\n"); exit(1); }
echo "ok ", strlen($hex), PHP_EOL;
'
