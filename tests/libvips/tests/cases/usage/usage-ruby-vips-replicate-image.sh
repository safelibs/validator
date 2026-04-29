#!/usr/bin/env bash
# @testcase: usage-ruby-vips-replicate-image
# @title: ruby-vips replicates image
# @description: Replicates a small image with ruby-vips and checks expanded dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-replicate-image"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(3, 2, bands: 1)
out = image.replicate(3, 4)
raise "unexpected dimensions" unless out.width == 9 && out.height == 8
puts "replicate #{out.width}x#{out.height}"
RUBY
