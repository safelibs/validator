#!/usr/bin/env bash
# @testcase: usage-ruby-vips-threshold-image
# @title: ruby-vips relational threshold
# @description: Applies a threshold comparison with ruby-vips and verifies numeric output.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-threshold-image"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

image = Vips::Image.black(4, 4, bands: 1) + 80
mask = image > 40
raise "empty mask" unless mask.avg > 0
puts "threshold #{mask.avg}"
RUBY
