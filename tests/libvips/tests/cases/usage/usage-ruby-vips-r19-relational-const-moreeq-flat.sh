#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-relational-const-moreeq-flat
# @title: ruby-vips Image#relational_const :moreeq with constant equal to pixel value returns all 255
# @description: Builds a 5x5 uchar image with constant value 50, calls relational_const(:moreeq, [50]) to test pixel-wise (pixel >= 50), asserts the result has the same width, height, and bands as the input and that every output pixel equals 255 (libvips relational truth value), and asserts a second call with constant 51 (strictly greater) yields all-zero output, confirming the inclusive >= threshold semantics.
# @timeout: 60
# @tags: usage, vips, ruby, relational, moreeq, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(5, 5) + 50).cast(:uchar)
eq = src.relational_const(:moreeq, [50])
raise "dims" unless eq.width == 5 && eq.height == 5
raise "bands=#{eq.bands}" unless eq.bands == src.bands
raise "true avg=#{eq.avg}" unless eq.avg == 255
raise "true min=#{eq.min}" unless eq.min == 255
raise "true max=#{eq.max}" unless eq.max == 255
gt = src.relational_const(:moreeq, [51])
raise "false avg=#{gt.avg}" unless gt.avg == 0
raise "false max=#{gt.max}" unless gt.max == 0
puts "moreeq true=#{eq.avg} false=#{gt.avg}"
RUBY
