# Dockerfile for creating a statically-linked Rust application using docker's
# multi-stage build feature. This also leverages the docker build cache to avoid
# re-downloading dependencies if they have not changed.

# Rust is a systems programming language focused on safety, speed, and concurrency.

FROM rust:1.52.1 AS build
WORKDIR /usr/src/basic-http-server

RUN rustup target add x86_64-unknown-linux-musl

RUN USER=root cargo install --target x86_64-unknown-linux-musl basic-http-server --version 0.6.3

# Copy the statically-linked binary into a scratch container.

FROM scratch
COPY --from=build /usr/local/cargo/bin/basic-http-server .
COPY index.html ./index.html
COPY swan.jpg ./swan.jpg
USER 1000
ENTRYPOINT ["./basic-http-server"]
CMD ["-x", "-a", "0.0.0.0:8080"]
