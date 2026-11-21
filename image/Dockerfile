# syntax=docker/dockerfile:1.7
#
# The scanner of the vulnerability management lab: Trivy, its vulnerability database, the
# images and projects the lab scans, and a frozen snapshot of EPSS and the KEV catalogue.
#
# **Nothing is downloaded when the lab runs.** A lab has no way out to the internet, so
# everything Trivy needs is put in here when the image is built, and every piece is pinned:
#   - Trivy 0.76.2, Aqua Security's official image, by digest.
#   - Trivy's vulnerability database, the OCI artifact ghcr.io/aquasecurity/trivy-db, by
#     digest. That one was published on 21 November 2026 (UpdatedAt 07:02 UTC), so every
#     copy of the lab answers from the same data, however old the image gets.
#   - The two images scanned, nginx 1.25.3 and 1.31.9 on Alpine, pulled by the digest of
#     their linux/amd64 manifests and saved as archives, so every machine scans the same bytes.
#   - snapshot/: EPSS scores of 20 November 2026 and CISA's KEV catalogue version 2026.11.20,
#     checked against SHA256SUMS before they are copied in.
# The download stages run on the build machine's own platform, so a two-architecture build
# needs no emulation, and the result is Trivy's own image with files added.

FROM --platform=$BUILDPLATFORM docker.io/aquasec/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb AS db
RUN trivy --cache-dir /opt/trivy image --download-db-only --no-progress --quiet \
      --db-repository ghcr.io/aquasecurity/trivy-db@sha256:1b05677e44b5562e39d201114b54dcc72a31c71687756c3d7a69f2e26044dc8e \
 && grep -q '"UpdatedAt":"2026-11-21T07:02:51' /opt/trivy/db/metadata.json \
 && chmod 0644 /opt/trivy/db/trivy.db /opt/trivy/db/metadata.json

FROM --platform=$BUILDPLATFORM gcr.io/go-containerregistry/crane:debug@sha256:e78770b31258a3846f878036d9c1f63fbe4c871f9f56990bf77fd95c013e3c1b AS images
SHELL ["/busybox/sh", "-c"]
RUN mkdir -p /out \
 && crane pull index.docker.io/library/nginx@sha256:b1cfc4e0e01b4dceca3265fd4ca97921569fca1a10919639bedfa8dad9127027 /out/web-1.25.3.tar \
 && crane pull index.docker.io/library/nginx@sha256:e68702efeaad0be9ced2b4d1cedb62cd15f5d51865d913955a883f653cd9e117 /out/web-1.31.9.tar \
 && chmod 0755 /out && chmod 0644 /out/*.tar

FROM --platform=$BUILDPLATFORM docker.io/library/alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f AS snapshot
COPY snapshot/ /snapshot/
RUN cd /snapshot && sha256sum -c SHA256SUMS

FROM docker.io/aquasec/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb
LABEL org.opencontainers.image.title="vuln-lab scanner" \
      org.opencontainers.image.description="Trivy 0.76.2 with its vulnerability database of 21 November 2026, two nginx images to scan and an EPSS and KEV snapshot of 20 November 2026, for a lab with no internet" \
      org.opencontainers.image.source="https://github.com/mitsurutech/lab-vuln-lab" \
      org.opencontainers.image.url="https://mitsurutech.co.uk/help/lab-vuln-lab" \
      org.opencontainers.image.vendor="Mitsuru Technologies" \
      org.opencontainers.image.licenses="Apache-2.0"
COPY --from=db /opt/trivy/db/ /opt/trivy/db/
COPY --from=images /out/ /targets/
COPY --from=snapshot /snapshot/ /snapshot/
COPY targets/ /targets/
COPY --chmod=0755 lab-start /usr/local/bin/lab-start
# Trivy reads these as if they were flags: the database in the image, never updated, no
# question sent anywhere, and its scan cache in memory, so nothing it needs is writable.
ENV TRIVY_CACHE_DIR=/opt/trivy \
    TRIVY_SKIP_DB_UPDATE=true \
    TRIVY_SKIP_JAVA_DB_UPDATE=true \
    TRIVY_SKIP_CHECK_UPDATE=true \
    TRIVY_SKIP_VERSION_CHECK=true \
    TRIVY_DISABLE_TELEMETRY=true \
    TRIVY_OFFLINE_SCAN=true \
    TRIVY_CACHE_BACKEND=memory \
    TRIVY_NO_PROGRESS=true \
    TRIVY_QUIET=true
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/lab-start"]
