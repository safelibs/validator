#!/usr/bin/env bash
# @testcase: usage-ruby-vips-ceil-fractional
# @title: ruby-vips ceil on fractional pixels
# @description: Applies Vips::Image#ceil to a synthetic float image with positive and negative fractional values and verifies ceil rounds toward positive infinity for each sampled pixel.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Mix of negative and positive fractional values plus an integer to confirm
# ceil leaves whole numbers untouched.
values = [-2.7, -0.5, 0.5, 2.4, 3.0]
src = Vips::Image.new_from_memory(values.pack('d*'), 5, 1, 1, :double)
raise "src dims" unless src.width == 5 && src.height == 1
raise "src format" unless src.format == :double

ceiled = src.ceil
raise "ceil dims" unless ceiled.width == 5 && ceiled.height == 1

expected = [-2.0, 0.0, 1.0, 3.0, 3.0]
expected.each_with_index do |want, x|
  got = ceiled.getpoint(x, 0)[0]
  raise "ceil(#{values[x]})=#{got} want #{want}" unless (got - want).abs < 1e-9
end

# floor(x) <= ceil(x) for every pixel.
floored = src.floor
(0...5).each do |x|
  f = floored.getpoint(x, 0)[0]
  c = ceiled.getpoint(x, 0)[0]
  raise "floor(#{values[x]})=#{f} > ceil=#{c}" unless f <= c
end

puts "ceil #{(0...5).map { |x| ceiled.getpoint(x, 0)[0] }.inspect}"
RUBY
