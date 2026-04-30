#!/usr/bin/env bash
# @testcase: usage-ruby-vips-recomb-color-matrix
# @title: ruby-vips recomb 3x3 color matrix
# @description: Applies a 3x3 channel recombination matrix to a synthetic 3-band sRGB image with Vips::Image#recomb and verifies that the per-band swap produces the expected pixel triple.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Synthetic uniform 3-band image with R=10, G=20, B=30.
src = (Vips::Image.black(8, 8, bands: 3) + [10, 20, 30]).cast(:uchar).copy(interpretation: :srgb)
raise "src bands" unless src.bands == 3
raise "src interp" unless src.interpretation == :srgb

# Permutation matrix that swaps R and B channels and leaves G alone:
#   out_R = 0*R + 0*G + 1*B
#   out_G = 0*R + 1*G + 0*B
#   out_B = 1*R + 0*G + 0*B
matrix = Vips::Image.new_from_array([
  [0.0, 0.0, 1.0],
  [0.0, 1.0, 0.0],
  [1.0, 0.0, 0.0],
])

out = src.recomb(matrix)
raise "out bands" unless out.bands == 3
raise "out dims" unless out.width == 8 && out.height == 8

px = out.getpoint(4, 4)
raise "recomb pixel #{px.inspect}" unless px.map { |v| v.round } == [30, 20, 10]

out_path = File.join(tmpdir, "recomb.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload bands" unless reload.bands == 3
raise "reload dims" unless reload.width == 8 && reload.height == 8
puts "recomb #{px.inspect}"
RUBY

file "$tmpdir/recomb.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/recomb.png")" >&2; exit 1; }
