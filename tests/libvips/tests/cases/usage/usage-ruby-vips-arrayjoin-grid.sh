#!/usr/bin/env bash
# @testcase: usage-ruby-vips-arrayjoin-grid
# @title: ruby-vips arrayjoin 2x2 grid
# @description: Combines four single-band tiles into a 2x2 grid via Vips::Image.arrayjoin with across:2 and verifies grid dimensions and per-quadrant pixel values.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

tile_size = 4
tl = (Vips::Image.black(tile_size, tile_size) + 11).cast(:uchar)
tr = (Vips::Image.black(tile_size, tile_size) + 22).cast(:uchar)
bl = (Vips::Image.black(tile_size, tile_size) + 33).cast(:uchar)
br = (Vips::Image.black(tile_size, tile_size) + 44).cast(:uchar)

grid = Vips::Image.arrayjoin([tl, tr, bl, br], across: 2)
raise "grid dims #{grid.width}x#{grid.height}" unless grid.width == 8 && grid.height == 8
raise "grid bands" unless grid.bands == 1

raise "tl pt" unless grid.getpoint(0, 0) == [11.0]
raise "tr pt" unless grid.getpoint(7, 0) == [22.0]
raise "bl pt" unless grid.getpoint(0, 7) == [33.0]
raise "br pt" unless grid.getpoint(7, 7) == [44.0]

out_path = File.join(tmpdir, "grid.png")
grid.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 8 && reload.height == 8
puts "arrayjoin 2x2 #{grid.width}x#{grid.height}"
RUBY

file "$tmpdir/grid.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/grid.png")" >&2; exit 1; }
