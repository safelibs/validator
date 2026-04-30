#!/usr/bin/env bash
# @testcase: usage-ruby-vips-canny-edges
# @title: ruby-vips canny edge detection
# @description: Runs Vips::Image#canny on a synthetic image with a hard vertical edge and verifies the response is non-zero along the edge and zero in flat regions.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 32x32 grayscale image, left half=0, right half=255. Build with a 1xH gradient
# row, then replicate vertically via embed/repeat: simpler to construct via a row
# array.
row = Array.new(32) { |x| x < 16 ? 0 : 255 }
mat = Vips::Image.new_from_array(Array.new(32) { row.dup })
src = mat.cast(:uchar)
raise "src dims" unless src.width == 32 && src.height == 32

edges = src.canny(sigma: 1.4)
raise "canny bands" unless edges.bands == 1
raise "canny dims" unless edges.width == 32 && edges.height == 32

# Far-left flat region should be ~0; the column straddling the step must be > 0.
flat_pt = edges.getpoint(2, 16)[0]
edge_pt = edges.getpoint(15, 16)[0] + edges.getpoint(16, 16)[0]
raise "flat #{flat_pt} not ~0" unless flat_pt.abs < 1.0
raise "edge #{edge_pt} not strong" unless edge_pt > 1.0

out_path = File.join(tmpdir, "canny.tif")
edges.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "canny flat=#{flat_pt} edge=#{edge_pt}"
RUBY

file "$tmpdir/canny.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/canny.tif")" >&2; exit 1; }
