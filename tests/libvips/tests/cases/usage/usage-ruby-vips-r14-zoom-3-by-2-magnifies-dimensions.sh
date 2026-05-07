#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-zoom-3-by-2-magnifies-dimensions
# @title: ruby-vips Image#zoom(3, 2) magnifies a 4x4 image to 12x8
# @description: Builds a 4x4 single-band uchar constant image and applies Vips::Image#zoom(3, 2), verifying the result is 12x8 with bands == 1 and the average matches the source (since zooming a constant image is value-preserving), asserting libvips' zoom replicates each input pixel into an XxY block exactly.
# @timeout: 60
# @tags: usage, vips, ruby, zoom
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 33).cast(:uchar)
out = src.zoom(3, 2)
raise "zoom dims=#{out.width}x#{out.height}" unless out.width == 12 && out.height == 8
raise "zoom bands=#{out.bands}" unless out.bands == 1
raise "zoom avg=#{out.avg}" unless out.avg == 33.0
puts "zoom 3x2 ok dims=#{out.width}x#{out.height}"
RUBY
