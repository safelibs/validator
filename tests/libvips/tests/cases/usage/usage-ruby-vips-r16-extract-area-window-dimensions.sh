#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-extract-area-window-dimensions
# @title: ruby-vips Image#extract_area returns the requested subregion with exact width and height
# @description: Builds a 16x16 single-band uchar constant image, calls extract_area(3, 4, 6, 5), and asserts the resulting region has width 6, height 5, bands 1, and the same mean as the source — exercising libvips' extract_area operator with explicit offsets.
# @timeout: 60
# @tags: usage, vips, ruby, extract-area
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(16, 16) + 77).cast(:uchar)
sub = src.extract_area(3, 4, 6, 5)
raise "dims=#{sub.width}x#{sub.height}" unless sub.width == 6 && sub.height == 5
raise "bands=#{sub.bands}" unless sub.bands == 1
raise "avg=#{sub.avg}" unless sub.avg == 77.0
puts "extract_area dims=#{sub.width}x#{sub.height} avg=#{sub.avg}"
RUBY
