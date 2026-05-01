#!/usr/bin/env bash
# @testcase: usage-ruby-vips-affine-shear
# @title: ruby-vips affine shear transform
# @description: Applies a horizontal shear via Vips::Image#affine with matrix [1, 0.5, 0, 1] to a small uchar image and verifies the output canvas is wider than the original while preserving the band count, then writes the result to PNG and reloads it.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src = (Vips::Image.black(20, 20) + 100).cast(:uchar)
raise "src dims" unless src.width == 20 && src.height == 20

# Affine matrix [a, b, c, d]: x' = a*x + b*y, y' = c*x + d*y.
# A horizontal shear with b=0.5 widens the bounding box.
out = src.affine([1.0, 0.5, 0.0, 1.0])
raise "shear bands" unless out.bands == src.bands
raise "shear height same" unless out.height == src.height
raise "shear width grew #{out.width}" unless out.width > src.width

out_path = File.join(tmpdir, "shear.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == out.width && reload.height == out.height
puts "affine shear #{src.width}x#{src.height} -> #{out.width}x#{out.height}"
RUBY

file "$tmpdir/shear.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/shear.png")" >&2; exit 1; }
