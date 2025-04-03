#!/usr/bin/bash

set -oeux pipefail

# enable linux-surface repo
dnf5 config-manager addrepo --from-repofile="https://pkg.surfacelinux.com/fedora/linux-surface.repo"

# remove existing kernel
existing_packages=( kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra libwacom libwacom-data )
rpm --erase "${existing_packages[@]}" --nodeps

dnf5 install -y \
    kernel-surface \
    kernel-surface-core \
    kernel-surface-modules \
    kernel-surface-modules-core \
    kernel-surface-modules-extra \
    kernel-surface-default-watchdog \
    libwacom-surface \
    libwacom-surface-data \
    libwacom-surface-utils \
    iptsd
