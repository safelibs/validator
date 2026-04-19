FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libuv1t64 \
      libuv1-dev \
      nodejs \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      jq \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libuv/ /validator/tests/libuv/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libuv/docker-entrypoint.sh /validator/tests/libuv/tests/run.sh \
 && if [ -d /validator/tests/libuv/tests/cases ]; then \
      find /validator/tests/libuv/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
