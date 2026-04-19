FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libpng16-16t64 \
      libpng-dev \
      libpng-tools \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      jq \
      pkg-config \
      python3 \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libpng/ /validator/tests/libpng/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libpng/docker-entrypoint.sh /validator/tests/libpng/tests/run.sh \
 && if [ -d /validator/tests/libpng/tests/cases ]; then \
      find /validator/tests/libpng/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
