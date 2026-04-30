#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-util-zero-bin2hex
# @title: RbNaCl Util.zeros and Util.bin2hex KAT
# @description: Builds a 32-byte zero buffer with RbNaCl::Util.zeros, asserts its length, content, and hex encoding via RbNaCl::Util.bin2hex, then encodes a known fixed byte sequence and asserts the exact lowercase hex matches the canonical expected string.
# @timeout: 180
# @tags: usage, crypto, util, encoding, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
zeros = RbNaCl::Util.zeros(32)
raise "unexpected zeros length: #{zeros.bytesize}" unless zeros.bytesize == 32
raise "zeros buffer not all NUL"           unless zeros.bytes.all? { |b| b == 0 }
raise "zeros hex mismatch"                 unless RbNaCl::Util.bin2hex(zeros) == "00" * 32

fixed = (0..15).to_a.pack("C*").force_encoding(Encoding::BINARY)
hex   = RbNaCl::Util.bin2hex(fixed)
expected = "000102030405060708090a0b0c0d0e0f"
raise "bin2hex KAT mismatch: #{hex}" unless hex == expected

# 64-byte buffer should hex-encode to exactly 128 lowercase chars.
buf = RbNaCl::Util.zeros(64)
raise "long zeros hex length wrong"        unless RbNaCl::Util.bin2hex(buf).length == 128
puts hex
'
