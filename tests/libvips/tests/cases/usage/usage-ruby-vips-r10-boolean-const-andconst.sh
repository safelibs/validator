#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-boolean-const-andconst
# @title: ruby-vips boolean_const bitwise AND with scalar mask
# @description: Applies Vips::Image#boolean_const(:and, [0x0F]) to mask the low nibble of a uint8 image and verifies the output bytes equal the bitwise AND of each sample with the scalar.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

samples = [0x00, 0x0F, 0xF0, 0xFF, 0xA5, 0x5A]
img = Vips::Image.new_from_memory(samples.pack('C*'), samples.length, 1, 1, :uchar)

masked = img.boolean_const(:and, [0x0F]).cast(:uchar)
raise "dims" unless masked.width == samples.length && masked.height == 1
raise "bands" unless masked.bands == 1

bytes = masked.write_to_memory.bytes
expected = samples.map { |s| s & 0x0F }
raise "and mismatch got=#{bytes.inspect} want=#{expected.inspect}" unless bytes == expected

# Symmetric :or with 0x80 sets high bit on every sample.
or_bytes = img.boolean_const(:or, [0x80]).cast(:uchar).write_to_memory.bytes
expected_or = samples.map { |s| s | 0x80 }
raise "or mismatch" unless or_bytes == expected_or

puts "boolean_const and/or ok"
RUBY
