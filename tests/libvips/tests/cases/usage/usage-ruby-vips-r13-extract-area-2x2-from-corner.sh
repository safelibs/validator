#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-extract-area-2x2-from-corner
# @title: ruby-vips Image#extract_area pulls a 2x2 region with the requested width and height
# @description: Builds an 8x8 constant uchar image and verifies extract_area(1, 2, 2, 2).width == 2 and .height == 2, asserting libvips' rectangle-extract honours the (left, top, width, height) arguments.
# @timeout: 60
# @tags: usage, vips, ruby, extract-area
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(8, 8) + 50).cast(:uchar)
out = img.extract_area(1, 2, 2, 2)
raise "extract_area dims=#{out.width}x#{out.height}" unless out.width == 2 && out.height == 2
raise "extract_area avg=#{out.avg}" unless out.avg == 50.0
puts "extract_area 2x2 avg=#{out.avg}"
RUBY
