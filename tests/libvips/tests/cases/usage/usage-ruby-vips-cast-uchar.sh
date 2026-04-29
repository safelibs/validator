#!/usr/bin/env bash
# @testcase: usage-ruby-vips-cast-uchar
# @title: ruby-vips casts image
# @description: Casts a ruby-vips image to unsigned byte format and verifies output format.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-cast-uchar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = (Vips::Image.black(4, 4, bands: 1) + 300).cast("uchar")
raise "unexpected format" unless image.format.to_s == "uchar"
puts "cast #{image.format}"
RUBY
