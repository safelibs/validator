FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libexif12 \
      libexif-dev \
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
COPY libexif/ /validator/tests/libexif/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libexif/docker-entrypoint.sh /validator/tests/libexif/tests/run.sh \
 && if [ -d /validator/tests/libexif/tests/cases ]; then \
      find /validator/tests/libexif/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
