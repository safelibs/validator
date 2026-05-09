#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sub-batch12
# @title: PHP sodium_sub modular subtraction
# @description: Builds two 16-byte little-endian counters, calls sodium_sub on copies of them and asserts the result equals the byte-wise representation of (a - b) mod 2**128, then crosses zero to confirm wrap-around: subtracting one from a zero buffer must yield the all-0xff buffer.
# @timeout: 60
# @tags: usage, crypto, arithmetic, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
// 1) (256, 1) -> (255, 0, ...)
$a = "\x00\x01" . str_repeat("\x00", 14);
$b = "\x01" . str_repeat("\x00", 15);
sodium_sub($a, $b);
$expect = "\xff\x00" . str_repeat("\x00", 14);
if ($a !== $expect) {
    fwrite(STDERR, "case1 mismatch: " . bin2hex($a) . "\n"); exit(1);
}
// 2) Underflow: 0 - 1 mod 2**128 = 0xff..ff
$z = str_repeat("\x00", 16);
$one = "\x01" . str_repeat("\x00", 15);
sodium_sub($z, $one);
$ff = str_repeat("\xff", 16);
if ($z !== $ff) {
    fwrite(STDERR, "underflow case mismatch: " . bin2hex($z) . "\n"); exit(1);
}
// 3) (a - a) is zero
$x = random_bytes(16);
$y = $x;
sodium_sub($x, $y);
if ($x !== str_repeat("\x00", 16)) {
    fwrite(STDERR, "self-subtract not zero: " . bin2hex($x) . "\n"); exit(1);
}
echo "ok\n";
PHP
