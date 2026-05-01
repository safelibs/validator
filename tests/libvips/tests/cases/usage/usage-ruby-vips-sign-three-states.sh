#!/usr/bin/env bash
# @testcase: usage-ruby-vips-sign-three-states
# @title: ruby-vips sign of negative zero positive
# @description: Constructs an image whose pixels span negative, zero, and positive values, applies Vips::Image#sign, and verifies that the output contains exactly the three values -1, 0, and 1 in the expected positions.
# @timeout: 120
# @tags: usage, ruby, image, arithmetic
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Row 0: negatives, row 1: zeros, row 2: positives.
src = Vips::Image.new_from_array([
  [-7.0, -2.0, -1.0],
  [0.0,  0.0,  0.0],
  [3.0,  10.0, 100.0],
])

sign = src.sign

# Expected sign values per row.
expected = [
  [-1.0, -1.0, -1.0],
  [0.0,  0.0,  0.0],
  [1.0,  1.0,  1.0],
]

(0...src.width).each do |x|
  (0...src.height).each do |y|
    got = sign.getpoint(x, y).first
    want = expected[y][x]
    raise "sign mismatch at #{x},#{y}: got=#{got} want=#{want}" unless got == want
  end
end

raise "sign min #{sign.min}" unless sign.min == -1.0
raise "sign max #{sign.max}" unless sign.max == 1.0
puts "sign min=#{sign.min} max=#{sign.max}"
RUBY
