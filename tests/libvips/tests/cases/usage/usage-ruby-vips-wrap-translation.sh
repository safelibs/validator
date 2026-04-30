#!/usr/bin/env bash
# @testcase: usage-ruby-vips-wrap-translation
# @title: ruby-vips wrap shifts image with toroidal wrap
# @description: Shifts a synthetic single-band test image by a non-trivial offset using Vips::Image#wrap and verifies that pixels reappear on the opposite edge as expected from the wrap-around semantics.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build a 4x3 single-band image with a unique value per pixel so any
# shift is detectable via getpoint.
pixels = [
  10, 20, 30, 40,
  50, 60, 70, 80,
  90, 100, 110, 120,
]
src = Vips::Image.new_from_memory(pixels.pack('C*'), 4, 3, 1, :uchar)
raise "src dims" unless src.width == 4 && src.height == 3

# wrap(x: dx, y: dy) translates the image toroidally so each output pixel
# at (i, j) reads from the input at ((i - dx) mod W, (j - dy) mod H).
# With dx=1, dy=1: output(0, 0) reads input(3, 2) (the bottom-right pixel
# wraps to the origin). output(1, 1) reads input(0, 0).
shifted = src.wrap(x: 1, y: 1)
raise "wrap dims" unless shifted.width == 4 && shifted.height == 3
raise "wrap (0,0) #{shifted.getpoint(0, 0).inspect}" unless shifted.getpoint(0, 0) == [120.0]
raise "wrap (1,1) #{shifted.getpoint(1, 1).inspect}" unless shifted.getpoint(1, 1) == [10.0]
raise "wrap (2,1) #{shifted.getpoint(2, 1).inspect}" unless shifted.getpoint(2, 1) == [20.0]

out_path = File.join(tmpdir, "wrap.png")
shifted.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "wrap dx=1 dy=1 (0,0)=#{shifted.getpoint(0, 0)[0].to_i}"
RUBY

file "$tmpdir/wrap.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/wrap.png")" >&2; exit 1; }
