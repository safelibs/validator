#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-multiply-by-two-doubles-mean
# @title: ruby-vips Image * 2 doubles the mean of a flat uchar image
# @description: Builds a 4x4 single-band uchar image with constant 30, multiplies by 2 via the Ruby operator, and verifies the result's mean is 60.0, asserting libvips' arithmetic-multiply with a scalar doubles each per-pixel value as expected.
# @timeout: 60
# @tags: usage, vips, ruby, multiply
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 30).cast(:uchar)
out = src * 2
raise "out dims=#{out.width}x#{out.height}" unless out.width == 4 && out.height == 4
raise "out avg=#{out.avg}" unless out.avg == 60.0
puts "multiply *2 avg=#{out.avg}"
RUBY
