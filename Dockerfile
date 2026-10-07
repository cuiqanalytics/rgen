# rgen, containerized. No binary lives in this repo — the image fetches the same Linux
# release tarball install.sh does, so `docker build` works from a clean checkout.
# To build from a local ./release.sh output instead:
#   docker build --build-arg RGEN_TARBALL=dist/rgen-cli-linux-x86_64.tar.gz -t rgen .
FROM debian:trixie-slim AS fetch
ARG RGEN_TARBALL=
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
COPY ${RGEN_TARBALL:-VERSION} /tmp/local-src
RUN if [ -n "${RGEN_TARBALL}" ]; then tar xzf /tmp/local-src -C /opt; \
    else curl -fsSL https://github.com/cuiqanalytics/rgen/releases/latest/download/rgen-cli-linux-x86_64.tar.gz \
         | tar xz -C /opt; fi \
    && mv /opt/rgen-cli-linux-x86_64 /opt/rgen

# The binary is dynamically linked against glibc (static glibc breaks vduckdb's dlopen() of
# libduckdb.so), so this image's glibc must be >= the release build machine's. That machine
# runs Debian trixie (glibc 2.41); bump this if it ever moves.
FROM debian:trixie-slim
COPY --from=fetch /opt/rgen/bin /usr/local/lib/rgen/bin
RUN chmod +x /usr/local/lib/rgen/bin/rgen
ENV LIBDUCKDB_DIR=/usr/local/lib/rgen/bin
ENV PATH="/usr/local/lib/rgen/bin:${PATH}"

# The lookup database (names, cities, companies...) is embedded in the binary and unpacked
# to $HOME/.local/share/rgen on first run. Do that once at build time, under a fixed HOME
# that any uid can read, so `--user "$(id -u):$(id -g)"` works (rgen opens it read-only).
ENV HOME=/home/rgen
RUN mkdir -p "$HOME" && rgen providers > /dev/null && chmod -R a+rX "$HOME"

# Output files land in the caller's working directory, which they mount here:
#   docker run --rm -v "$PWD:/work" ghcr.io/cuiqanalytics/rgen run -n 1000 users.csv
# Own the output files:  --user "$(id -u):$(id -g)"
# Data packs + license:  -v ~/.cuiq:/home/rgen/.cuiq:ro -v ~/.local/share/rgen/packs:/home/rgen/.local/share/rgen/packs:ro
WORKDIR /work
ENTRYPOINT ["rgen"]
