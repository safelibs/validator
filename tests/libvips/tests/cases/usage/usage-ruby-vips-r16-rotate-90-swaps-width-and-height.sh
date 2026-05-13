#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-rotate-90-swaps-width-and-height
# @title: ruby-vips Image#rot90 on a 20x12 image yields a 12x20 image with preserved mean
# @description: Builds a 20x12 single-band uchar constant image with value 25, applies Vips::Image#rot90, and asserts the result has width 12, height 20, bands 1, and identical mean — exercising libvips' 90-degree rotation operator's geometry change.
# @timeout: 60
# @tags: usage, vips, ruby, rotate
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(20, 12) + 25).cast(:uchar)
out = src.rot90
raise "dims=#{out.width}x#{out.height}" unless out.width == 12 && out.height == 20
raise "bands=#{out.bands}" unless out.bands == 1
raise "avg=#{out.avg}" unless out.avg == 25.0
puts "rot90 dims=#{out.width}x#{out.height}"
RUBY
