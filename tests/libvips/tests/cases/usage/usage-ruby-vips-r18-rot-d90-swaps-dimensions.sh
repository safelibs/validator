#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-rot-d90-swaps-dimensions
# @title: ruby-vips Image#rot(:d90) swaps width and height of a non-square input
# @description: Builds a 9x4 uchar image (non-square so rotation effects are observable), rotates by 90 degrees with rot(:d90), and asserts the result has width 4, height 9, and the same band count as the input, confirming libvips' lossless 90-degree rotation transposes the canvas dimensions.
# @timeout: 60
# @tags: usage, vips, ruby, rot, rotate, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(9, 4) + 17).cast(:uchar)
out = src.rot(:d90)
raise "width=#{out.width}"   unless out.width == 4
raise "height=#{out.height}" unless out.height == 9
raise "bands=#{out.bands}"   unless out.bands == src.bands
puts "rot90 #{out.width}x#{out.height}"
RUBY
