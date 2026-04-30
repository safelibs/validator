#!/usr/bin/env bash
# @testcase: usage-ruby-vips-new-from-array-pixels
# @title: ruby-vips new_from_array pixel payload
# @description: Builds a small image with Vips::Image.new_from_array and verifies dimensions and per-pixel values via getpoint.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

mat = Vips::Image.new_from_array([[1, 2, 3], [4, 5, 6]])
raise "size #{mat.width}x#{mat.height}" unless mat.width == 3 && mat.height == 2
raise "bands #{mat.bands}" unless mat.bands == 1
raise "pt 0,0 #{mat.getpoint(0, 0).inspect}" unless mat.getpoint(0, 0) == [1.0]
raise "pt 2,1 #{mat.getpoint(2, 1).inspect}" unless mat.getpoint(2, 1) == [6.0]

out_path = File.join(tmpdir, "from_array.png")
(mat.cast(:uchar)).write_to_file(out_path)
raise "missing png output" unless File.exist?(out_path) && File.size(out_path) > 0
puts "new_from_array #{mat.width}x#{mat.height}"
RUBY

out_path="$tmpdir/from_array.png"
[[ -s "$out_path" ]] || { echo "missing png" >&2; exit 1; }
file "$out_path" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$out_path")" >&2; exit 1; }
