#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-identity-lut-shape
# @title: ruby-vips identity LUT maps inputs to themselves
# @description: Builds an 8-bit identity LUT with Vips::Image.identity, verifies the dimensions are 256x1, and checks several sampled positions return their own index value.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

lut = Vips::Image.identity
raise "bands" unless lut.bands == 1
raise "dims #{lut.width}x#{lut.height}" unless lut.width == 256 && lut.height == 1

[0, 1, 7, 64, 127, 128, 200, 255].each do |x|
  v = lut.getpoint(x, 0)[0]
  raise "identity[#{x}] got=#{v}" unless v == x.to_f
end

# Use the LUT to map an image: maplut should be the identity transform.
src = Vips::Image.new_from_memory([5, 17, 200, 255].pack('C*'), 4, 1, 1, :uchar)
mapped = src.maplut(lut).cast(:uchar)
raise "maplut" unless mapped.write_to_memory.bytes == [5, 17, 200, 255]

puts "identity LUT identity-check ok"
RUBY
