#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-rot180-roundtrip-identity
# @title: ruby-vips two rot180 calls return the original 2x2 pixel buffer
# @description: Builds a 2x2 single-band uchar image with bytes [1, 2, 3, 4] and verifies rot180.rot180.write_to_memory.bytes is again [1, 2, 3, 4], asserting libvips' 180-degree rotation is its own inverse on a square buffer.
# @timeout: 60
# @tags: usage, vips, ruby, rotate, rot180
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = Vips::Image.new_from_memory([1, 2, 3, 4].pack('C*'), 2, 2, 1, :uchar)
once = src.rot180
raise "rot180 bytes=#{once.write_to_memory.bytes.inspect}" unless once.write_to_memory.bytes == [4, 3, 2, 1]
twice = once.rot180
raise "double rot180 bytes=#{twice.write_to_memory.bytes.inspect}" unless twice.write_to_memory.bytes == [1, 2, 3, 4]
puts "rot180 identity ok"
RUBY
