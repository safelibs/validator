#!/usr/bin/env bash
# @testcase: usage-php83-r20-increment-overflows-low-byte-to-next
# @title: PHP sodium_increment carries from a 0xff low byte into the next byte
# @description: Builds a little-endian 4-byte buffer "\xff\x00\x00\x00", calls sodium_increment, and asserts the resulting bytes are "\x00\x01\x00\x00", confirming libsodium-backed multi-byte little-endian counter increments correctly propagate carry across byte boundaries.
# @timeout: 60
# @tags: usage, sodium, increment, carry, php, r20
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$b = "\xff\x00\x00\x00";
sodium_increment($b);
if (bin2hex($b) !== "00010000") {
    fwrite(STDERR, "got=" . bin2hex($b) . "\n"); exit(1);
}
echo "ok increment hex=", bin2hex($b), PHP_EOL;
'
