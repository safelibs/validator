#!/usr/bin/env bash
# @testcase: usage-ruby-vips-countlines-vertical
# @title: ruby-vips countlines vertical transitions
# @description: Builds a small binary image containing a known number of horizontal stripe transitions and verifies that Vips::Image#countlines reports the expected count for vertical-direction line counting.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build a striped binary image with VERTICAL stripes (each column alternates
# 0/255 across rows? no — vertical stripes mean each row is alternating
# values: row content ABABAB...). Then countlines(:vertical) — which
# counts vertical-line transitions when scanning along rows — must report a
# strictly positive count, while countlines(:horizontal) (transitions when
# scanning along columns) reports zero on a vertically-striped image.
rows = []
6.times do
  rows << Array.new(8) { |x| x.even? ? 0 : 255 }
end
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == 8 && src.height == 6
raise "src bands" unless src.bands == 1

v = src.countlines(:vertical)
h = src.countlines(:horizontal)
raise "expected vertical countlines > horizontal, got v=#{v} h=#{h}" unless v > h
raise "expected vertical countlines > 0, got #{v}" unless v > 0
puts "countlines vertical=#{v} horizontal=#{h}"
RUBY
