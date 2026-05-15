#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-abs-of-negative-constant
# @title: ruby-vips Image#abs flips the sign of a negative signed-format image to positive
# @description: Builds an 8x6 image with constant value -40 cast to signed :char format, calls abs, and asserts the result has the same width, height, and band count as the input, asserts every pixel value in the result equals 40 (avg=40, min=40, max=40), confirming libvips' absolute-value operator correctly negates signed pixels.
# @timeout: 60
# @tags: usage, vips, ruby, abs, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 6) - 40).cast(:char)
out = src.abs
raise "dims" unless out.width == 8 && out.height == 6
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "avg=#{out.avg}" unless out.avg == 40
raise "min=#{out.min}" unless out.min == 40
raise "max=#{out.max}" unless out.max == 40
puts "abs avg=#{out.avg}"
RUBY
