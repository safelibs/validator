#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-flip-horizontal-restores-via-double-flip
# @title: ruby-vips two horizontal flips restore the original byte order
# @description: Builds a 1x3 single-band uchar image with values [10, 20, 30] and verifies that two consecutive flip(:horizontal) calls restore the original write_to_memory bytes [10, 20, 30], asserting libvips horizontal flip is its own inverse.
# @timeout: 60
# @tags: usage, vips, ruby, flip
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = Vips::Image.new_from_memory([10, 20, 30].pack('C*'), 3, 1, 1, :uchar)
once = src.flip(:horizontal)
raise "single flip bytes=#{once.write_to_memory.bytes.inspect}" unless once.write_to_memory.bytes == [30, 20, 10]
twice = once.flip(:horizontal)
raise "double flip bytes=#{twice.write_to_memory.bytes.inspect}" unless twice.write_to_memory.bytes == [10, 20, 30]
puts "double-flip identity"
RUBY
