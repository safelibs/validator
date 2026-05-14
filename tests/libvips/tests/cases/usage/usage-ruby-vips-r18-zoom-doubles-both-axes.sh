#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-zoom-doubles-both-axes
# @title: ruby-vips Image#zoom(2, 2) doubles width and height with nearest-neighbour replication
# @description: Builds an 8x6 uchar image, calls zoom(2, 2) to nearest-neighbour replicate each pixel, and asserts the result has width 16 (2x), height 12 (2x), the same band count, and the same avg as the input since nearest-neighbour replication preserves the mean exactly.
# @timeout: 60
# @tags: usage, vips, ruby, zoom, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 6) + 40).cast(:uchar)
out = src.zoom(2, 2)
raise "width=#{out.width}"   unless out.width == 16
raise "height=#{out.height}" unless out.height == 12
raise "bands=#{out.bands}"   unless out.bands == src.bands
raise "avg=#{out.avg}"       unless out.avg == src.avg
puts "zoom #{out.width}x#{out.height}"
RUBY
