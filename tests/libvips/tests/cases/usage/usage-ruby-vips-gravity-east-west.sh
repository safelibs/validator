#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gravity-east-west
# @title: ruby-vips gravity east and west alignment
# @description: Pads a 2x2 source image into a 4x4 canvas with Vips::Image#gravity using east and west placements and verifies the source pixels land vertically centred against the requested edge.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 2x2 single-band image with distinct corner values.
src = Vips::Image.new_from_array([[10, 20], [30, 40]]).cast(:uchar)
raise "src dims" unless src.width == 2 && src.height == 2

# East: hugs the right edge, vertically centred. The 2x2 source lands
# in columns 2..3 of a 4x4 canvas, vertically at rows 1..2.
east = src.gravity(:east, 4, 4, extend: :black)
raise "east dims" unless east.width == 4 && east.height == 4
# Right edge has the source.
raise "east 2,1 #{east.getpoint(2, 1).inspect}" unless east.getpoint(2, 1) == [10.0]
raise "east 3,1 #{east.getpoint(3, 1).inspect}" unless east.getpoint(3, 1) == [20.0]
raise "east 2,2 #{east.getpoint(2, 2).inspect}" unless east.getpoint(2, 2) == [30.0]
raise "east 3,2 #{east.getpoint(3, 2).inspect}" unless east.getpoint(3, 2) == [40.0]
# Far-left column must be background.
raise "east 0,1 #{east.getpoint(0, 1).inspect}" unless east.getpoint(0, 1) == [0.0]

# West: hugs the left edge, vertically centred -> source lands in columns 0..1.
west = src.gravity(:west, 4, 4, extend: :black)
raise "west dims" unless west.width == 4 && west.height == 4
raise "west 0,1 #{west.getpoint(0, 1).inspect}" unless west.getpoint(0, 1) == [10.0]
raise "west 1,1 #{west.getpoint(1, 1).inspect}" unless west.getpoint(1, 1) == [20.0]
raise "west 0,2 #{west.getpoint(0, 2).inspect}" unless west.getpoint(0, 2) == [30.0]
raise "west 1,2 #{west.getpoint(1, 2).inspect}" unless west.getpoint(1, 2) == [40.0]
# Far-right column must be background.
raise "west 3,1 #{west.getpoint(3, 1).inspect}" unless west.getpoint(3, 1) == [0.0]

out_path = File.join(tmpdir, "gravity_ew.png")
west.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "gravity east/west ok"
RUBY

file "$tmpdir/gravity_ew.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/gravity_ew.png")" >&2; exit 1; }
