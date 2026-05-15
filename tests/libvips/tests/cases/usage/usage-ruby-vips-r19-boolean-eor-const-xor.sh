#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-boolean-eor-const-xor
# @title: ruby-vips Image#boolean_const with :eor and constant 255 inverts a uchar image
# @description: Builds a 4x4 uchar image with constant value 0x0F (15), calls boolean_const(:eor, [0xFF]) to bitwise-XOR every pixel with 255, asserts the result has the same dimensions and band count as the input, and asserts every output pixel equals 0xF0 (240) via avg, min, and max checks, confirming libvips' boolean_const XOR (eor) operator semantics.
# @timeout: 60
# @tags: usage, vips, ruby, boolean, xor, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 0x0F).cast(:uchar)
out = src.boolean_const(:eor, [0xFF])
raise "dims" unless out.width == 4 && out.height == 4
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "avg=#{out.avg}" unless out.avg == 0xF0
raise "min=#{out.min}" unless out.min == 0xF0
raise "max=#{out.max}" unless out.max == 0xF0
puts "eor avg=#{out.avg}"
RUBY
