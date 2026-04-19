FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libzstd1 \
      libzstd-dev \
      zstd \
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
COPY libzstd/ /validator/tests/libzstd/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libzstd/docker-entrypoint.sh /validator/tests/libzstd/tests/run.sh \
 && if [ -d /validator/tests/libzstd/tests/cases ]; then \
      find /validator/tests/libzstd/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
