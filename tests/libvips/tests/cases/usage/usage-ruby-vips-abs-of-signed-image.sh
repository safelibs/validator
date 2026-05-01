#!/usr/bin/env bash
# @testcase: usage-ruby-vips-abs-of-signed-image
# @title: ruby-vips abs of signed image
# @description: Casts a uchar image to signed char, subtracts a constant to introduce negative pixel values, then applies Vips::Image#abs and verifies that all output pixels are non-negative and equal to the magnitude of the signed input.
# @timeout: 120
# @tags: usage, ruby, image, arithmetic
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build an image with values 0..30, then shift to -30..0 using float math.
src = Vips::Image.new_from_array([
  [0, 5, 10, 15],
  [20, 25, 30, 30],
])
shifted = (src - 30.0)
raise "shifted min #{shifted.min}" unless shifted.min == -30.0
raise "shifted max #{shifted.max}" unless shifted.max == 0.0

abs = shifted.abs
raise "abs min #{abs.min}" unless abs.min == 0.0
raise "abs max #{abs.max}" unless abs.max == 30.0

# Each pixel of abs equals magnitude of the shifted pixel.
(0...src.width).each do |x|
  (0...src.height).each do |y|
    s = shifted.getpoint(x, y).first
    a = abs.getpoint(x, y).first
    raise "abs mismatch #{x},#{y} s=#{s} a=#{a}" unless a == s.abs
  end
end

out_path = File.join(tmpdir, "abs.png")
abs.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "abs min=#{abs.min} max=#{abs.max}"
RUBY

file "$tmpdir/abs.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/abs.png")" >&2; exit 1; }
