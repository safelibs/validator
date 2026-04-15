FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

COPY docker/ubuntu-src.sources /etc/apt/sources.list.d/ubuntu-src.sources
COPY docker/dependents-packages.txt /opt/libuv-safe/dependents-packages.txt
COPY docker/run-dependent-probes.sh /usr/local/bin/run-dependent-probes.sh
COPY debs/libuv-runtime.deb /tmp/libuv-runtime.deb
COPY debs/libuv-dev.deb /tmp/libuv-dev.deb

RUN chmod 0755 /usr/local/bin/run-dependent-probes.sh \
    && apt-get update \
    && xargs -r apt-get install -y --no-install-recommends </opt/libuv-safe/dependents-packages.txt \
    && dpkg -i /tmp/libuv-runtime.deb /tmp/libuv-dev.deb \
    && rm -f /tmp/libuv-runtime.deb /tmp/libuv-dev.deb \
    && rm -rf /var/lib/apt/lists/*
