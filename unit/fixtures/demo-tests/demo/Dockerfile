FROM ubuntu:24.04

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY demo/ /validator/tests/demo/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/demo/docker-entrypoint.sh \
    /validator/tests/demo/tests/run.sh
