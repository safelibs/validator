#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-replicate-doubles-width
# @title: ruby-vips Image#replicate(2,1) doubles the width and preserves the height
# @description: Builds an 8x6 uchar image, calls replicate(2, 1) to tile the input 2-wide by 1-tall, and asserts the result has width 16 (2x), height 6 (1x), and the same band count as the input, confirming libvips' tiling-replicate geometry.
# @timeout: 60
# @tags: usage, vips, ruby, replicate, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 6) + 30).cast(:uchar)
out = src.replicate(2, 1)
raise "width=#{out.width}" unless out.width == 16
raise "height=#{out.height}" unless out.height == 6
raise "bands=#{out.bands}" unless out.bands == src.bands
puts "replicate #{out.width}x#{out.height}"
RUBY
