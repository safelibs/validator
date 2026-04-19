FROM ubuntu:24.04

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY original-demo/ /validator/tests/original-demo/

RUN chmod +x \
    /validator/tests/_shared/install_override_debs.sh \
    /validator/tests/original-demo/tests/cases/source/echo-source.sh \
    /validator/tests/original-demo/tests/cases/usage/echo-client.sh
