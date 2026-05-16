#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-hist-find-bin-count-256
# @title: ruby-vips Image#hist_find on a uchar image produces a 256-wide one-pixel-tall histogram
# @description: Constructs a 16x16 uchar image of constant value 42, calls hist_find, and asserts the histogram image is 256 wide, 1 tall, single-banded, with the only non-zero bin at column 42 equal to 16*16=256, exercising libvips' histogram bucketing operation.
# @timeout: 60
# @tags: usage, vips, ruby, hist-find, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(16, 16) + 42).cast(:uchar)
h = src.hist_find
raise "width=#{h.width}" unless h.width == 256
raise "height=#{h.height}" unless h.height == 1
raise "bands=#{h.bands}" unless h.bands == 1
bin = h.getpoint(42, 0)
raise "bin42=#{bin.inspect}" unless bin[0] == 256
zero_left = h.getpoint(41, 0)
raise "bin41=#{zero_left.inspect}" unless zero_left[0] == 0
puts "hist bin42=#{bin[0]}"
RUBY
