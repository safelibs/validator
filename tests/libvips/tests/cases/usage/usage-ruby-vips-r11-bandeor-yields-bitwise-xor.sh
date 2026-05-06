#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-bandeor-yields-bitwise-xor
# @title: ruby-vips Image#bandeor xors all bands together
# @description: Builds a 1x1 two-band image with bytes 0xff and 0x0f and verifies Image#bandeor returns the single-band byte 0xf0 (bitwise xor).
# @timeout: 60
# @tags: usage, vips, ruby, bands, bitwise
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.new_from_memory([0xff, 0x0f].pack("C*"), 1, 1, 2, :uchar)
xor = img.bandeor
raise "xor bands #{xor.bands}" unless xor.bands == 1
v = xor.getpoint(0, 0).first
raise "xor[0,0] got #{v}" unless v == 240.0
puts "bandeor 0xff^0x0f = #{v.to_i.to_s(16)}"
RUBY
