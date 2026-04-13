FROM ubuntu:24.04

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY demo-pass/ /validator/tests/demo-pass/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/demo-pass/docker-entrypoint.sh \
    /validator/tests/demo-pass/tests/run.sh
