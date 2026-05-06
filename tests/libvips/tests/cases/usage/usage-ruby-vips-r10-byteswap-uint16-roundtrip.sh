#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-byteswap-uint16-roundtrip
# @title: ruby-vips byteswap on 16-bit data is its own inverse
# @description: Constructs a uint16 image, applies Vips::Image#byteswap twice, and verifies the round-trip restores the original samples while a single byteswap reorders the byte pairs.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

samples = [0x1234, 0xABCD, 0x00FF, 0xFF00]
raw = samples.pack('S<*')
img = Vips::Image.new_from_memory(raw, samples.length, 1, 1, :ushort)

once = img.byteswap
twice = once.byteswap

# Single byteswap: low/high byte pair flipped.
swapped_bytes = once.write_to_memory.bytes
expected_swapped = samples.flat_map { |v| [(v >> 8) & 0xFF, v & 0xFF] }
raise "single swap mismatch" unless swapped_bytes == expected_swapped

# Double byteswap restores original ushort samples.
restored_bytes = twice.write_to_memory.bytes
expected_original = samples.flat_map { |v| [v & 0xFF, (v >> 8) & 0xFF] }
raise "double swap mismatch" unless restored_bytes == expected_original

puts "byteswap roundtrip ok bytes=#{swapped_bytes.length}"
RUBY
