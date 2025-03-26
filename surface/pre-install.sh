#!/usr/bin/bash

set -oeux pipefail

curl --create-dirs --output-dir /tmp/surface-rpms -sLO https://pkg.surfacelinux.com/fedora/f"${FEDORA_MAJOR_VERSION}"/kernel-surface-"${KERNEL_VERSION}".rpm
curl --create-dirs --output-dir /tmp/surface-rpms -sLO https://pkg.surfacelinux.com/fedora/f"${FEDORA_MAJOR_VERSION}"/kernel-surface-core-"${KERNEL_VERSION}".rpm
curl --create-dirs --output-dir /tmp/surface-rpms -sLO https://pkg.surfacelinux.com/fedora/f"${FEDORA_MAJOR_VERSION}"/kernel-surface-modules-"${KERNEL_VERSION}".rpm
curl --create-dirs --output-dir /tmp/surface-rpms -sLO https://pkg.surfacelinux.com/fedora/f"${FEDORA_MAJOR_VERSION}"/kernel-surface-modules-core-"${KERNEL_VERSION}".rpm
curl --create-dirs --output-dir /tmp/surface-rpms -sLO https://pkg.surfacelinux.com/fedora/f"${FEDORA_MAJOR_VERSION}"/kernel-surface-modules-extra-"${KERNEL_VERSION}".rpm
curl --create-dirs --output-dir /tmp/surface-rpms -sLO https://pkg.surfacelinux.com/fedora/f"${FEDORA_MAJOR_VERSION}"/kernel-surface-default-watchdog-"${KERNEL_VERSION}".rpm

/ctx/github-release-install.sh --repository=linux-surface/iptsd --asset-filter="fc${FEDORA_MAJOR_VERSION}" --download-only --output-dir=/tmp/surface-rpms

/ctx/github-release-install.sh --repository=linux-surface/libwacom-surface --asset-filter="surface-\d.*\.fc${FEDORA_MAJOR_VERSION}" --download-only --output-dir=/tmp/surface-rpms
/ctx/github-release-install.sh --repository=linux-surface/libwacom-surface --asset-filter="surface-data-\d.*\.fc${FEDORA_MAJOR_VERSION}" --download-only --output-dir=/tmp/surface-rpms
/ctx/github-release-install.sh --repository=linux-surface/libwacom-surface --asset-filter="surface-utils-\d.*\.fc${FEDORA_MAJOR_VERSION}" --download-only --output-dir=/tmp/surface-rpms

# do HWE specific things
curl -Lo /etc/yum.repos.d/linux-surface.repo \
    https://pkg.surfacelinux.com/fedora/linux-surface.repo

rpm-ostree cliwrap install-to-root /
rpm-ostree override replace \
    --experimental \
    --remove kernel \
    --remove kernel-core \
    --remove kernel-modules \
    --remove kernel-modules-core \
    --remove kernel-modules-extra \
    --remove libwacom \
    --remove libwacom-data \
    /tmp/surface-rpms/kernel-surface*.rpm \
    /tmp/surface-rpms/libwacom-surface*.rpm \
    /tmp/surface-rpms/iptsd*.rpm
