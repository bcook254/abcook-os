ARG SOURCE_NS="${SOURCE_NS:-quay.io}"
ARG SOURCE_ORG="${SOURCE_ORG:-fedora}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-fedora}"
# Source variant can be null
ARG SOURCE_VARIANT="${SOURCE_VARIANT}"
ARG IMAGE_NAME="${IMAGE_VARIANT:-base}"
ARG IMAGE_VARIANT="${IMAGE_VARIANT:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"

FROM ghcr.io/ublue-os/config:latest AS config
FROM ghcr.io/ublue-os/akmods:main-${FEDORA_MAJOR_VERSION} AS akmods

FROM scratch AS ctx
COPY / /

FROM ${SOURCE_NS}/${SOURCE_ORG}/${SOURCE_IMAGE}${SOURCE_VARIANT}:${FEDORA_MAJOR_VERSION} AS main

ARG IMAGE_NAME="${IMAGE_NAME:-base}"
ARG IMAGE_VARIANT="${IMAGE_VARIANT:-main}"
ARG KERNEL_VERSION="${KERNEL_VERSION}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,src=/,dst=/ctx \
    --mount=type=bind,from=config,src=/rpms,dst=/tmp/config-rpms \
    --mount=type=bind,from=akmods,src=/rpms/ublue-os,dst=/tmp/akmods-rpms \
    /ctx/pre-install.sh && \
    /ctx/install.sh && \
    /ctx/post-install.sh && \
    # Cleanup everything we don't need
    /ctx/cleanup.sh && \
    ostree container commit && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp
