FROM ubuntu:24.04

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY demo-fail/ /validator/tests/demo-fail/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/demo-fail/docker-entrypoint.sh \
    /validator/tests/demo-fail/tests/run.sh
