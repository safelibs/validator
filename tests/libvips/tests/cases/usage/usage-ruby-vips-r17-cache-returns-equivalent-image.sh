#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-cache-returns-equivalent-image
# @title: ruby-vips Image#cache returns an image with identical dimensions and mean
# @description: Builds a 12x12 uchar image with constant value 77, calls cache(), and asserts the cached image has identical width, height, bands, format, and average pixel value as the source, confirming libvips' tile cache wrapper preserves pixel semantics.
# @timeout: 60
# @tags: usage, vips, ruby, cache, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(12, 12) + 77).cast(:uchar)
out = src.cache
raise "width=#{out.width}" unless out.width == src.width
raise "height=#{out.height}" unless out.height == src.height
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "format=#{out.format}" unless out.format == src.format
raise "avg out=#{out.avg} src=#{src.avg}" unless out.avg == src.avg
puts "cache avg=#{out.avg}"
RUBY
