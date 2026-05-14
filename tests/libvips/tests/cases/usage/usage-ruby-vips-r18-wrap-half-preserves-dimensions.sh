#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-wrap-half-preserves-dimensions
# @title: ruby-vips Image#wrap by half width and height preserves dimensions and statistics
# @description: Builds a 10x8 uchar image with constant value 55, calls wrap(5, 4) to cyclically shift the image by half its width and half its height, and asserts the result has the same width, height, band count, and avg/min/max as the input, confirming libvips' wrap is a cyclic permutation that preserves all per-pixel statistics on a constant image.
# @timeout: 60
# @tags: usage, vips, ruby, wrap, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(10, 8) + 55).cast(:uchar)
out = src.wrap(x: 5, y: 4)
raise "dims #{out.width}x#{out.height}" unless out.width == 10 && out.height == 8
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "avg mismatch" unless out.avg == src.avg
raise "min mismatch" unless out.min == src.min
raise "max mismatch" unless out.max == src.max
puts "wrap #{out.width}x#{out.height}"
RUBY
