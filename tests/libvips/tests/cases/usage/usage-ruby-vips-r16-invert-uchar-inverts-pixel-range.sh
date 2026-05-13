#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-invert-uchar-inverts-pixel-range
# @title: ruby-vips Image#invert maps a uchar constant 70 image to a uchar constant 185 image
# @description: Builds a 5x5 single-band uchar image with constant value 70, calls Image#invert, and asserts the result has the same 5x5 dimensions and an average of exactly 185.0 (255 - 70), exercising libvips' invert operator over the uchar range.
# @timeout: 60
# @tags: usage, vips, ruby, invert
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(5, 5) + 70).cast(:uchar)
out = src.invert
raise "dims=#{out.width}x#{out.height}" unless out.width == 5 && out.height == 5
raise "avg=#{out.avg}" unless out.avg == 185.0
puts "invert avg=#{out.avg}"
RUBY
