#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-ceil-of-fractional-2-3-equals-3
# @title: ruby-vips Image#ceil on a constant 2.3 float yields 3
# @description: Builds a 4x4 image with constant value 2.3 cast to float, calls .ceil, and asserts the result avg, min, and max are all exactly 3.0 (ceil(2.3)==3), confirming libvips' ceil operator rounds upward toward positive infinity for a positive fractional input.
# @timeout: 60
# @tags: usage, vips, ruby, ceil, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 2.3).cast(:float)
out = src.ceil
raise "avg=#{out.avg}" unless (out.avg - 3.0).abs < 1e-6
raise "min=#{out.min}" unless (out.min - 3.0).abs < 1e-6
raise "max=#{out.max}" unless (out.max - 3.0).abs < 1e-6
puts "ok ceil(2.3) avg=#{out.avg}"
RUBY
