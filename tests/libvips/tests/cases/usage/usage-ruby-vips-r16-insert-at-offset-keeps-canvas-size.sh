#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-insert-at-offset-keeps-canvas-size
# @title: ruby-vips Image#insert places a small image into a canvas without changing canvas dimensions
# @description: Builds a 20x20 single-band uchar canvas with constant 10 and a 4x4 sub-image with constant 200, calls canvas.insert(sub, 5, 6), and asserts the result has width 20, height 20, bands 1, and a mean strictly greater than the canvas mean (10.0) — exercising libvips' insert operator with explicit offsets.
# @timeout: 60
# @tags: usage, vips, ruby, insert
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
canvas = (Vips::Image.black(20, 20) + 10).cast(:uchar)
sub = (Vips::Image.black(4, 4) + 200).cast(:uchar)
out = canvas.insert(sub, 5, 6)
raise "dims=#{out.width}x#{out.height}" unless out.width == 20 && out.height == 20
raise "bands=#{out.bands}" unless out.bands == 1
raise "avg=#{out.avg}" unless out.avg > 10.0
puts "insert avg=#{out.avg}"
RUBY
