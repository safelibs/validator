#!/usr/bin/env bash
# @testcase: usage-php83-sodium-increment-batch12
# @title: PHP sodium_increment, sodium_compare, sodium_pad
# @description: Drives sodium_increment to roll a 16-byte little-endian counter from 0xFF over to 0x100, uses sodium_compare to order three nonces in lexical-LE form, and round-trips a payload through sodium_pad/sodium_unpad against a fixed block size to verify the padding plumbing in php-sodium.
# @timeout: 60
# @tags: usage, crypto, arithmetic, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
// 1) sodium_increment: 0x00FF... + 1 == 0x0001 0x0001 0x00 ...
$counter = "\xff" . str_repeat("\x00", 15);
sodium_increment($counter);
$expect = "\x00\x01" . str_repeat("\x00", 14);
if ($counter !== $expect) {
    fwrite(STDERR, "increment mismatch: " . bin2hex($counter) . "\n"); exit(1);
}

// 2) sodium_compare orders little-endian counters: a < b < c.
$a = "\x01" . str_repeat("\x00", 15);
$b = "\x02" . str_repeat("\x00", 15);
$c = "\x00\x01" . str_repeat("\x00", 14); // = 256
if (sodium_compare($a, $b) !== -1) {
    fwrite(STDERR, "compare a<b failed\n"); exit(1);
}
if (sodium_compare($b, $a) !== 1) {
    fwrite(STDERR, "compare b>a failed\n"); exit(1);
}
if (sodium_compare($a, $a) !== 0) {
    fwrite(STDERR, "compare a==a failed\n"); exit(1);
}
if (sodium_compare($b, $c) !== -1) {
    fwrite(STDERR, "compare b<c failed (LE)\n"); exit(1);
}

// 3) sodium_pad / sodium_unpad round-trip on a non-aligned payload.
$payload = "validator-pad-input-12345"; // 25 bytes
$block = 16;
$padded = sodium_pad($payload, $block);
if (strlen($padded) % $block !== 0) {
    fwrite(STDERR, "pad length not block-aligned: " . strlen($padded) . "\n"); exit(1);
}
if (strlen($padded) <= strlen($payload)) {
    fwrite(STDERR, "pad did not grow payload\n"); exit(1);
}
$unpadded = sodium_unpad($padded, $block);
if ($unpadded !== $payload) {
    fwrite(STDERR, "unpad mismatch: " . bin2hex($unpadded) . "\n"); exit(1);
}
echo "ok\n";
PHP
