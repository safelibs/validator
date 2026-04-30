#!/usr/bin/env bash
# @testcase: usage-ruby-vips-similarity-rotate-30
# @title: ruby-vips similarity rotation by 30 degrees
# @description: Rotates a synthetic single-band image by 30 degrees via Vips::Image#similarity and verifies the rotated canvas grows beyond the original square dimensions.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src = (Vips::Image.black(40, 40) + 100).cast(:uchar)
raise "src dims" unless src.width == 40 && src.height == 40

out = src.similarity(angle: 30.0)
# A 30 degree rotation of a square produces a strictly larger bounding box.
raise "similarity did not enlarge: #{out.width}x#{out.height}" unless out.width > 40 && out.height > 40
raise "similarity bands" unless out.bands == src.bands

out_path = File.join(tmpdir, "similarity.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload mismatch" unless reload.width == out.width && reload.height == out.height
puts "similarity 30deg #{src.width}x#{src.height} -> #{out.width}x#{out.height}"
RUBY

file "$tmpdir/similarity.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/similarity.png")" >&2; exit 1; }
