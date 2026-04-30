#!/usr/bin/env bash
# @testcase: usage-ruby-vips-grid-tile-layout
# @title: ruby-vips grid relays a tall image into tiles
# @description: Stacks four 6x6 tiles vertically via arrayjoin then uses Vips::Image#grid to relay them into a 2x2 layout, verifying final dimensions and per-tile sentinel pixels.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

tile = 6
a = (Vips::Image.black(tile, tile) + 11).cast(:uchar)
b = (Vips::Image.black(tile, tile) + 22).cast(:uchar)
c = (Vips::Image.black(tile, tile) + 33).cast(:uchar)
d = (Vips::Image.black(tile, tile) + 44).cast(:uchar)

# Build a vertical strip of four tiles (one column, tile*4 tall).
strip = Vips::Image.arrayjoin([a, b, c, d], across: 1)
raise "strip dims" unless strip.width == tile && strip.height == tile * 4

# grid lays the strip out as 2 across, with the strip pre-divided into tiles
# of the given tile_height. Result should be a 2x2 layout.
out = strip.grid(tile, 2, 2)
raise "grid dims #{out.width}x#{out.height}" unless out.width == tile * 2 && out.height == tile * 2

# Top-left tile is `a`, top-right is `b`, bottom-left is `c`, bottom-right is `d`.
raise "tl pt" unless out.getpoint(0, 0) == [11.0]
raise "tr pt" unless out.getpoint(tile + 1, 0) == [22.0]
raise "bl pt" unless out.getpoint(0, tile + 1) == [33.0]
raise "br pt" unless out.getpoint(tile + 1, tile + 1) == [44.0]

out_path = File.join(tmpdir, "grid.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "grid #{out.width}x#{out.height}"
RUBY

file "$tmpdir/grid.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/grid.png")" >&2; exit 1; }
