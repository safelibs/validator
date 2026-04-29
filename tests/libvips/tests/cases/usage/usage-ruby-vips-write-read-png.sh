#!/usr/bin/env bash
# @testcase: usage-ruby-vips-write-read-png
# @title: ruby-vips write and read PNG
# @description: Writes a synthetic PNG with ruby-vips, reloads it, and verifies the round-trip dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-write-read-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(6, 4, bands: 3) + 200
path = File.join(tmpdir, "roundtrip.png")
image.write_to_file(path)
reload = Vips::Image.new_from_file(path)
raise "unexpected roundtrip" unless reload.width == 6 && reload.height == 4
puts "roundtrip #{reload.width}x#{reload.height}"
RUBY
