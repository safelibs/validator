#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-subsample-by-two-halves-dimensions
# @title: ruby-vips Image#subsample(2, 2) halves the width and height of an input
# @description: Builds a 16x10 uchar image, calls subsample(2, 2) to take every second pixel along each axis, and asserts the result has width 8 (16/2), height 5 (10/2), and the same band count as the input, confirming libvips' point-sampled downsample geometry.
# @timeout: 60
# @tags: usage, vips, ruby, subsample, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(16, 10) + 22).cast(:uchar)
out = src.subsample(2, 2)
raise "width=#{out.width}"   unless out.width == 8
raise "height=#{out.height}" unless out.height == 5
raise "bands=#{out.bands}"   unless out.bands == src.bands
puts "subsample #{out.width}x#{out.height}"
RUBY
