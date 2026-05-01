#!/usr/bin/env bash
# @testcase: usage-ruby-vips-boolean-and-image
# @title: ruby-vips boolean AND between two images
# @description: Builds two single-band uchar images with distinct bit patterns and verifies that Vips::Image#boolean(:and) computes the per-pixel bitwise AND of the two inputs at every sample position.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

a_pixels = [0b11110000, 0b10101010, 0b11111111, 0b00001111]
b_pixels = [0b00111100, 0b11001100, 0b01010101, 0b11110000]

a = Vips::Image.new_from_memory(a_pixels.pack('C*'), 4, 1, 1, :uchar)
b = Vips::Image.new_from_memory(b_pixels.pack('C*'), 4, 1, 1, :uchar)

result = a.boolean(b, :and)
raise "result dims" unless result.width == 4 && result.height == 1
raise "result bands" unless result.bands == 1

(0...4).each do |x|
  expected = a_pixels[x] & b_pixels[x]
  got = result.getpoint(x, 0)[0]
  raise "(#{x}) and = #{got} want #{expected}" unless got == expected.to_f
end

# Also verify OR for completeness.
or_img = a.boolean(b, :or)
(0...4).each do |x|
  expected = a_pixels[x] | b_pixels[x]
  got = or_img.getpoint(x, 0)[0]
  raise "(#{x}) or = #{got} want #{expected}" unless got == expected.to_f
end

puts "boolean and/or ok"
RUBY
