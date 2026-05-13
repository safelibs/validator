#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-add-scalar-shifts-mean-by-constant
# @title: ruby-vips Image + scalar shifts the mean of a flat uchar image by the constant
# @description: Builds an 8x8 single-band uchar image with constant value 30, adds 25 via the Ruby operator, and asserts the result's mean is exactly 55.0 with identical 8x8 dimensions, exercising libvips' arithmetic-add with a scalar.
# @timeout: 60
# @tags: usage, vips, ruby, add
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 30).cast(:uchar)
out = src + 25
raise "dims=#{out.width}x#{out.height}" unless out.width == 8 && out.height == 8
raise "avg=#{out.avg}" unless out.avg == 55.0
puts "add scalar avg=#{out.avg}"
RUBY
