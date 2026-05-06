#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-parse-sequence-flow-style-true-event
# @title: PyYAML parse marks SequenceStartEvent.flow_style True for flow input
# @description: Parses a flow-style sequence "[1, 2, 3]" via yaml.parse and asserts the SequenceStartEvent emitted carries flow_style=True, with three intermediate ScalarEvents and a SequenceEndEvent — distinguishing flow-source events from block sequences.
# @timeout: 60
# @tags: usage, python3-yaml, parse, events
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

events = list(yaml.parse('[1, 2, 3]'))
seq_starts = [e for e in events if isinstance(e, yaml.SequenceStartEvent)]
assert len(seq_starts) == 1, [type(e).__name__ for e in events]
assert seq_starts[0].flow_style is True, seq_starts[0].flow_style
scalars = [e for e in events if isinstance(e, yaml.ScalarEvent)]
assert [e.value for e in scalars] == ['1', '2', '3'], [e.value for e in scalars]
ends = [e for e in events if isinstance(e, yaml.SequenceEndEvent)]
assert len(ends) == 1, len(ends)
PY
