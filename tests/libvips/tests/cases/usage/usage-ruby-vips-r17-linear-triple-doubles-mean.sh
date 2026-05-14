#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-linear-triple-doubles-mean
# @title: ruby-vips Image#linear with all-twos slopes doubles the mean of a flat uchar image
# @description: Builds an 8x8 single-band uchar image with constant value 40, applies linear([2.0, 2.0, 2.0], [0.0, 0.0, 0.0]) to scale per band, asserts the result preserves the 8x8 dimensions and the average pixel value equals exactly 80.0, exercising libvips' linear operation.
# @timeout: 60
# @tags: usage, vips, ruby, linear, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 40).cast(:uchar)
out = src.linear([2.0, 2.0, 2.0], [0.0, 0.0, 0.0])
raise "dims=#{out.width}x#{out.height}" unless out.width == 8 && out.height == 8
raise "avg=#{out.avg}" unless out.avg == 80.0
puts "linear avg=#{out.avg}"
RUBY
