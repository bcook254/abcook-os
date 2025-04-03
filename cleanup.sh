#!/usr/bin/bash

set -eoux pipefail
shopt -s extglob

# Cleanup
# Remove tmp files and everything in dirs that make bootc unhappy
rm -rf /tmp/* || true
rm -rf /usr/etc
rm -rf /boot && mkdir /boot
find /var/lib /var/cache -maxdepth 1 -mindepth 1 ! -wholename /var/lib/alternatives ! -wholename /var/cache/libdnf5 -type d -exec rm -rv {} +
find /var -maxdepth 1 -mindepth 1 ! -wholename /var/lib ! -wholename /var/cache -type d -exec rm -rv {} +

# Make sure /var/tmp is properly created
mkdir -p /var/tmp && chmod -R 1777 /var/tmp

# bootc/ostree checks
bootc container lint
