#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-bandjoin-three-images-makes-three-bands
# @title: ruby-vips Image#bandjoin with two extra single-band images yields a 3-band output
# @description: Builds three independent 5x5 single-band uchar images, calls bandjoin([b, c]) on the first to stack the channels, and asserts the result has width 5, height 5, bands 3, and per-band averages equal to the originals' avg values (10, 20, 30), confirming libvips' band concatenation order and pixel pass-through.
# @timeout: 60
# @tags: usage, vips, ruby, bandjoin, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
a = (Vips::Image.black(5, 5) + 10).cast(:uchar)
b = (Vips::Image.black(5, 5) + 20).cast(:uchar)
c = (Vips::Image.black(5, 5) + 30).cast(:uchar)
out = a.bandjoin([b, c])
raise "dims #{out.width}x#{out.height}" unless out.width == 5 && out.height == 5
raise "bands=#{out.bands}" unless out.bands == 3
raise "avg=#{out.extract_band(0).avg}" unless out.extract_band(0).avg == 10.0
raise "avg=#{out.extract_band(1).avg}" unless out.extract_band(1).avg == 20.0
raise "avg=#{out.extract_band(2).avg}" unless out.extract_band(2).avg == 30.0
puts "bandjoin 3 bands"
RUBY
