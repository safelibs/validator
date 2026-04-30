#!/usr/bin/env bash
# @testcase: usage-ruby-vips-relational-more
# @title: ruby-vips relational more produces boolean mask
# @description: Compares two synthetic images with relational :more and verifies the boolean mask is 255 where lhs > rhs and 0 elsewhere.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

a = Vips::Image.new_from_array([[10, 20], [30, 40]]).cast(:uchar)
b = Vips::Image.new_from_array([[15, 15], [15, 15]]).cast(:uchar)

mask = a.relational(b, :more)
raise "mask dims" unless mask.width == 2 && mask.height == 2
raise "mask bands" unless mask.bands == 1

# vips relational returns 255 where true, 0 where false (uchar).
raise "0,0 #{mask.getpoint(0, 0).inspect}" unless mask.getpoint(0, 0) == [0.0]
raise "1,0 #{mask.getpoint(1, 0).inspect}" unless mask.getpoint(1, 0) == [255.0]
raise "0,1 #{mask.getpoint(0, 1).inspect}" unless mask.getpoint(0, 1) == [255.0]
raise "1,1 #{mask.getpoint(1, 1).inspect}" unless mask.getpoint(1, 1) == [255.0]

out_path = File.join(tmpdir, "mask.png")
mask.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "relational more ok"
RUBY

file "$tmpdir/mask.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/mask.png")" >&2; exit 1; }
