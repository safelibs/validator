#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandjoin-extract-roundtrip
# @title: ruby-vips bandjoin then extract_band roundtrip
# @description: Joins three single-band images, extracts each band back out, and verifies the recovered scalar values.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

a = (Vips::Image.black(2, 2) + 11).cast(:uchar)
b = (Vips::Image.black(2, 2) + 22).cast(:uchar)
c = (Vips::Image.black(2, 2) + 33).cast(:uchar)

joined = a.bandjoin([b, c])
raise "bands #{joined.bands}" unless joined.bands == 3
raise "joined pt" unless joined.getpoint(1, 1) == [11.0, 22.0, 33.0]

raise "extract 0" unless joined.extract_band(0).getpoint(0, 0) == [11.0]
raise "extract 1" unless joined.extract_band(1).getpoint(0, 0) == [22.0]
raise "extract 2" unless joined.extract_band(2).getpoint(0, 0) == [33.0]

out_path = File.join(tmpdir, "joined.png")
joined.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload bands #{reload.bands}" unless reload.bands == 3
puts "bandjoin/extract_band ok"
RUBY

file "$tmpdir/joined.png" | grep -q 'PNG image data' || { echo "not a PNG" >&2; exit 1; }
