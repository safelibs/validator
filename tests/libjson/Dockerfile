FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libjson-c5 \
      libjson-c-dev \
      bash \
      build-essential \
      ca-certificates \
      cmake \
      coreutils \
      file \
      jq \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libjson/ /validator/tests/libjson/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libjson/docker-entrypoint.sh /validator/tests/libjson/tests/run.sh \
 && if [ -d /validator/tests/libjson/tests/cases ]; then \
      find /validator/tests/libjson/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
