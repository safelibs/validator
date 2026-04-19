FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libgif7 \
      libgif-dev \
      giflib-tools \
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
COPY giflib/ /validator/tests/giflib/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/giflib/docker-entrypoint.sh /validator/tests/giflib/tests/run.sh \
 && if [ -d /validator/tests/giflib/tests/cases ]; then \
      find /validator/tests/giflib/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
