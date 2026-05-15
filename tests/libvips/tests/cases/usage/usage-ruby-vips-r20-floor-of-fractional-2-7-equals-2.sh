#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-floor-of-fractional-2-7-equals-2
# @title: ruby-vips Image#floor on a constant 2.7 float yields 2
# @description: Builds a 4x4 image with constant value 2.7 cast to float, calls .floor, and asserts the result avg, min, and max are all exactly 2.0 (floor(2.7)==2), confirming libvips' floor operator correctly truncates toward negative infinity on a positive fractional.
# @timeout: 60
# @tags: usage, vips, ruby, floor, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 2.7).cast(:float)
out = src.floor
raise "avg=#{out.avg}" unless (out.avg - 2.0).abs < 1e-6
raise "min=#{out.min}" unless (out.min - 2.0).abs < 1e-6
raise "max=#{out.max}" unless (out.max - 2.0).abs < 1e-6
puts "ok floor(2.7) avg=#{out.avg}"
RUBY
