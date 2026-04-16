FROM ubuntu:24.04

ARG VALIDATOR_BASELINE_FIXTURE=demo-host-baseline

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY demo-host/ /validator/tests/demo-host/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/demo-host/host-run.sh \
    /validator/tests/demo-host/tests/harness-source/original-test-script.sh
