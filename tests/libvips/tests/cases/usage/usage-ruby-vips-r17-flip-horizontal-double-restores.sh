#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-flip-horizontal-double-restores
# @title: ruby-vips Image#flip(:horizontal) applied twice restores pixel-equal output
# @description: Builds a 4x4 uchar image filled with constant value 90, flips it horizontally twice, computes the sum of absolute differences between the doubly-flipped output and the original via (out - src).abs.avg, and asserts the average pixel-difference is exactly 0.0 — confirming libvips' horizontal flip is an involution.
# @timeout: 60
# @tags: usage, vips, ruby, flip, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 90).cast(:uchar)
out = src.flip(:horizontal).flip(:horizontal)
raise "dims=#{out.width}x#{out.height}" unless out.width == 4 && out.height == 4
diff = (out - src).abs.avg
raise "diff=#{diff}" unless diff == 0.0
puts "flip double diff=#{diff}"
RUBY
