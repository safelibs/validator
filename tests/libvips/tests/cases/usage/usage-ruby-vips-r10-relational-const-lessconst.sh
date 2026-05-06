#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-relational-const-lessconst
# @title: ruby-vips relational_const less than scalar
# @description: Compares an integer image against a scalar threshold via Vips::Image#relational_const(:less, [...]) and verifies the output marks samples below the threshold with 255 and the rest with 0.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

samples = [10, 99, 100, 101, 200]
threshold = 100
img = Vips::Image.new_from_memory(samples.pack('C*'), samples.length, 1, 1, :uchar)

mask = img.relational_const(:less, [threshold]).cast(:uchar)
raise "dims" unless mask.width == samples.length && mask.height == 1
raise "bands" unless mask.bands == 1

bytes = mask.write_to_memory.bytes
expected = samples.map { |s| s < threshold ? 255 : 0 }
raise "less mismatch got=#{bytes.inspect} want=#{expected.inspect}" unless bytes == expected

# Mirror with relational_const :moreeq for the complementary mask.
mirror = img.relational_const(:moreeq, [threshold]).cast(:uchar).write_to_memory.bytes
expected_mirror = samples.map { |s| s >= threshold ? 255 : 0 }
raise "moreeq mismatch" unless mirror == expected_mirror

puts "relational_const less ok #{bytes.join(',')}"
RUBY
