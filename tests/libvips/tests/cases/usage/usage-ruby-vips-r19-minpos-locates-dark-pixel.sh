#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-minpos-locates-dark-pixel
# @title: ruby-vips Image#minpos returns the coordinate of the darkest pixel in a planted-spot image
# @description: Builds a 6x6 uchar image with constant value 200, draws a single pixel of value 5 at (4, 1) via draw_rect on a mutable copy, calls minpos on the result, asserts the returned (min_value, x, y) tuple equals (5, 4, 1), confirming libvips' min-position locator picks the correct minimum coordinate against a planted dark spot.
# @timeout: 60
# @tags: usage, vips, ruby, minpos, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(6, 6) + 200).cast(:uchar)
planted = src.mutate { |m| m.draw_rect!(5, 4, 1, 1, 1) }
v, x, y = planted.minpos
raise "min v=#{v}" unless v == 5
raise "x=#{x}" unless x == 4
raise "y=#{y}" unless y == 1
puts "minpos v=#{v} at (#{x},#{y})"
RUBY
