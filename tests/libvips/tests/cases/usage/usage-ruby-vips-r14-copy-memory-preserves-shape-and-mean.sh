#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-copy-memory-preserves-shape-and-mean
# @title: ruby-vips Image#copy_memory preserves dimensions, bands, and mean
# @description: Builds a 7x5 single-band uchar constant image, calls Vips::Image#copy_memory to materialise it into RAM, and verifies the returned image has the same dimensions, band count, and average pixel value as the source, asserting libvips' copy_memory marker is value-preserving and does not change the image's logical shape.
# @timeout: 60
# @tags: usage, vips, ruby, copy-memory
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(7, 5) + 64).cast(:uchar)
mem = src.copy_memory
raise "copy_memory dims=#{mem.width}x#{mem.height}" unless mem.width == 7 && mem.height == 5
raise "copy_memory bands=#{mem.bands}" unless mem.bands == 1
raise "copy_memory avg=#{mem.avg}" unless mem.avg == 64.0
puts "copy_memory ok dims=#{mem.width}x#{mem.height} avg=#{mem.avg}"
RUBY
