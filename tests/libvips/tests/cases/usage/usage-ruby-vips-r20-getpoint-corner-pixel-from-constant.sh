#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-getpoint-corner-pixel-from-constant
# @title: ruby-vips Image#getpoint(0, 0) on a constant image returns the constant value
# @description: Builds an 8x8 image with every pixel equal to 123 (uchar), calls .getpoint(0, 0), and asserts the returned array has length equal to the band count and the sole value equals 123.0, confirming libvips' single-pixel sampling API returns the underlying pixel for the trivial constant case.
# @timeout: 60
# @tags: usage, vips, ruby, getpoint, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 123).cast(:uchar)
arr = src.getpoint(0, 0)
raise "len=#{arr.length}" unless arr.length == src.bands
raise "val=#{arr.first}" unless (arr.first - 123.0).abs < 1e-9
puts "ok getpoint=#{arr.first}"
RUBY
