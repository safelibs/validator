#!/usr/bin/env bash
# @testcase: usage-ruby-vips-floor-fractional
# @title: ruby-vips floor on fractional pixels
# @description: Applies Vips::Image#floor to a synthetic float image with positive and negative fractional values and verifies floor rounds toward negative infinity for each sampled pixel.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 5x1 single-band double image with values that exercise both signs and
# the integer boundary case (3.0 -> 3.0).
values = [-2.7, -0.5, 0.5, 2.4, 3.0]
src = Vips::Image.new_from_memory(values.pack('d*'), 5, 1, 1, :double)
raise "src dims" unless src.width == 5 && src.height == 1
raise "src format" unless src.format == :double

floored = src.floor
raise "floor dims" unless floored.width == 5 && floored.height == 1

expected = [-3.0, -1.0, 0.0, 2.0, 3.0]
expected.each_with_index do |want, x|
  got = floored.getpoint(x, 0)[0]
  raise "floor(#{values[x]})=#{got} want #{want}" unless (got - want).abs < 1e-9
end

# Round-trip floored values through a uchar-safe range to make sure floor
# is composable with subsequent ops.
shifted = floored + 5
shifted_pix = (0...5).map { |x| shifted.getpoint(x, 0)[0] }
raise "shifted #{shifted_pix.inspect}" unless shifted_pix == [2.0, 4.0, 5.0, 7.0, 8.0]

puts "floor #{(0...5).map { |x| floored.getpoint(x, 0)[0] }.inspect}"
RUBY
