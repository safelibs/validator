FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libyaml-0-2 \
      libyaml-dev \
      python3-yaml \
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
COPY libyaml/ /validator/tests/libyaml/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libyaml/docker-entrypoint.sh /validator/tests/libyaml/tests/run.sh \
 && if [ -d /validator/tests/libyaml/tests/cases ]; then \
      find /validator/tests/libyaml/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
