#!/usr/bin/env bash
# @testcase: usage-ruby-vips-sobel-edges
# @title: ruby-vips sobel edge magnitude
# @description: Runs Vips::Image#sobel on an image with a sharp vertical step and verifies the response peaks along the step column and is near zero in flat regions.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

row = Array.new(20) { |x| x < 10 ? 0 : 255 }
mat = Vips::Image.new_from_array(Array.new(20) { row.dup })
src = mat.cast(:uchar)
raise "src dims" unless src.width == 20 && src.height == 20

edges = src.sobel
raise "sobel dims" unless edges.width == 20 && edges.height == 20
raise "sobel bands" unless edges.bands == 1

flat_left = edges.getpoint(1, 10)[0]
flat_right = edges.getpoint(18, 10)[0]
edge_strength = edges.getpoint(9, 10)[0] + edges.getpoint(10, 10)[0]

raise "flat_left #{flat_left}" unless flat_left.abs < 1.0
raise "flat_right #{flat_right}" unless flat_right.abs < 1.0
raise "edge_strength #{edge_strength}" unless edge_strength > 100.0

out_path = File.join(tmpdir, "sobel.tif")
edges.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "sobel flatL=#{flat_left} flatR=#{flat_right} edge=#{edge_strength}"
RUBY

file "$tmpdir/sobel.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/sobel.tif")" >&2; exit 1; }
