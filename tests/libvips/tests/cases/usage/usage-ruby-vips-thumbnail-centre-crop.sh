#!/usr/bin/env bash
# @testcase: usage-ruby-vips-thumbnail-centre-crop
# @title: ruby-vips thumbnail with centre crop
# @description: Generates a thumbnail of a synthetic image with crop:centre and verifies the output is exactly square at the requested size.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src_path="$tmpdir/src.png"
ruby -rvips - "$src_path" <<'RUBY'
src_path = ARGV[0]
img = (Vips::Image.black(160, 80, bands: 3) + [120, 30, 200]).cast(:uchar)
img.write_to_file(src_path)
raise "missing src" unless File.size?(src_path)
RUBY

[[ -s "$src_path" ]] || { echo "missing source png" >&2; exit 1; }
file "$src_path" | grep -q 'PNG image data' || { echo "src is not a PNG" >&2; exit 1; }

ruby -rvips - "$src_path" "$tmpdir" <<'RUBY'
src_path = ARGV[0]
tmpdir = ARGV[1]

thumb = Vips::Image.thumbnail(src_path, 64, height: 64, crop: :centre)
raise "thumb dims #{thumb.width}x#{thumb.height}" unless thumb.width == 64 && thumb.height == 64

out_path = File.join(tmpdir, "thumb.png")
thumb.cast(:uchar).write_to_file(out_path)
raise "missing thumb" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 64 && reload.height == 64
puts "thumbnail #{reload.width}x#{reload.height}"
RUBY

file "$tmpdir/thumb.png" | grep -q 'PNG image data' || { echo "thumb not a PNG" >&2; exit 1; }
