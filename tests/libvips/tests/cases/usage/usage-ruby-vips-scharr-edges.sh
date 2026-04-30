#!/usr/bin/env bash
# @testcase: usage-ruby-vips-scharr-edges
# @title: ruby-vips scharr edge detection
# @description: Runs Vips::Image#scharr on a synthetic image with a vertical step and verifies the response peaks along the step column and is near zero in flat regions.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

row = Array.new(24) { |x| x < 12 ? 0 : 255 }
mat = Vips::Image.new_from_array(Array.new(24) { row.dup })
src = mat.cast(:uchar)
raise "src dims" unless src.width == 24 && src.height == 24

edges = src.scharr
raise "scharr dims" unless edges.width == 24 && edges.height == 24
raise "scharr bands" unless edges.bands == 1

flat_left = edges.getpoint(2, 12)[0]
flat_right = edges.getpoint(21, 12)[0]
edge_strength = edges.getpoint(11, 12)[0] + edges.getpoint(12, 12)[0]

raise "flat_left #{flat_left}" unless flat_left.abs < 1.0
raise "flat_right #{flat_right}" unless flat_right.abs < 1.0
raise "edge_strength #{edge_strength}" unless edge_strength > 100.0

out_path = File.join(tmpdir, "scharr.tif")
edges.cast(:uchar).write_to_file(out_path)
raise "missing tif" unless File.size?(out_path)
puts "scharr flatL=#{flat_left} flatR=#{flat_right} edge=#{edge_strength}"
RUBY

file "$tmpdir/scharr.tif" | grep -qE 'TIFF image data' || { echo "not a TIFF: $(file "$tmpdir/scharr.tif")" >&2; exit 1; }
