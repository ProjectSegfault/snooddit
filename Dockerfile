####################################################################################################
## Builder
####################################################################################################
FROM rust:alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /snooddit

COPY . .

RUN cargo build --target x86_64-unknown-linux-musl --release

####################################################################################################
## Final image
####################################################################################################
FROM alpine:latest

# Import ca-certificates from builder
COPY --from=builder /usr/share/ca-certificates /usr/share/ca-certificates
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

# Copy our build
COPY --from=builder /snooddit/target/x86_64-unknown-linux-musl/release/snooddit /usr/local/bin/snooddit

# Use an unprivileged user.
RUN adduser --home /nonexistent --no-create-home --disabled-password snooddit
USER snooddit

# Tell Docker to expose port 8080
EXPOSE 8080

# Run a healthcheck every minute to make sure snooddit is functional
HEALTHCHECK --interval=1m --timeout=3s CMD wget --spider --q http://localhost:8080/settings || exit 1

CMD ["snooddit"]
