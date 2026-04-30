#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gravity-placement
# @title: ruby-vips gravity placement directions
# @description: Pads a small image with Vips::Image.gravity using north-west and south-east placements and verifies that the original pixels land in the expected corners.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Single-band 2x2 image with distinct corner values.
src = Vips::Image.new_from_array([[10, 20], [30, 40]]).cast(:uchar)
raise "src dims" unless src.width == 2 && src.height == 2

nw = src.gravity(:north_west, 4, 4, extend: :black)
raise "nw dims" unless nw.width == 4 && nw.height == 4
raise "nw 0,0 #{nw.getpoint(0, 0).inspect}" unless nw.getpoint(0, 0) == [10.0]
raise "nw 1,1 #{nw.getpoint(1, 1).inspect}" unless nw.getpoint(1, 1) == [40.0]
raise "nw 3,3 #{nw.getpoint(3, 3).inspect}" unless nw.getpoint(3, 3) == [0.0]

se = src.gravity(:south_east, 4, 4, extend: :black)
raise "se dims" unless se.width == 4 && se.height == 4
raise "se 0,0 #{se.getpoint(0, 0).inspect}" unless se.getpoint(0, 0) == [0.0]
raise "se 2,2 #{se.getpoint(2, 2).inspect}" unless se.getpoint(2, 2) == [10.0]
raise "se 3,3 #{se.getpoint(3, 3).inspect}" unless se.getpoint(3, 3) == [40.0]

out_path = File.join(tmpdir, "gravity.png")
se.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "gravity nw/se ok #{nw.width}x#{nw.height}"
RUBY

file "$tmpdir/gravity.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/gravity.png")" >&2; exit 1; }
