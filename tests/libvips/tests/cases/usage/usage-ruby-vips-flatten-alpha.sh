#!/usr/bin/env bash
# @testcase: usage-ruby-vips-flatten-alpha
# @title: ruby-vips flatten alpha
# @description: Flattens an RGBA image with ruby-vips and verifies alpha removal.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-flatten-alpha"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(4, 4, bands: 4) + [10, 20, 30, 128]
flat = image.flatten(background: [255, 255, 255])
raise "unexpected bands" unless flat.bands == 3
puts "flatten #{flat.bands}"
RUBY
