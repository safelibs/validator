#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-histogram-bins-length
# @title: ruby-vips Image#hist_find on a uchar image yields a 256-bin histogram
# @description: Builds a 32x32 uchar image, runs hist_find to compute the per-bin histogram, and asserts the resulting histogram image has width 256 (one bin per uchar value) and height 1, confirming libvips' histogram bin layout for 8-bit input.
# @timeout: 60
# @tags: usage, vips, ruby, histogram, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(32, 32) + 64).cast(:uchar)
hist = src.hist_find
raise "hist width=#{hist.width}" unless hist.width == 256
raise "hist height=#{hist.height}" unless hist.height == 1
puts "hist_find bins=#{hist.width}"
RUBY
