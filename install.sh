#!/usr/bin/bash

set -oeux pipefail

RELEASE="$(rpm -E %fedora)"
ARCH="$(uname -m)"
case $ARCH in
  
  x86_64)
    ARCH_ALT="amd64"
    ;;
  aarch64)
    ARCH_ALT="arm64"
    ;;
  *)
    ARCH_ALT="unknown"
    ;;
esac

# mitigate upstream packaging bug: https://bugzilla.redhat.com/show_bug.cgi?id=2332429
# swap the incorrectly installed OpenCL-ICD-Loader for ocl-icd, the expected package
dnf5 swap -y --repo='fedora' \
    OpenCL-ICD-Loader ocl-icd

dnf5 -y copr enable ublue-os/packages
dnf5 -y copr enable ublue-os/staging

dnf5 install -y \
    ublue-os-just \
    ublue-os-luks \
    ublue-os-signing \
    ublue-os-udev-rules \
    ublue-os-update-services \
    fedora-repos-archive

# use negativo17 for 3rd party packages with higher priority than default
dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
dnf5 config-manager setopt fedora-multimedia.priority=90

# use override to replace mesa and others with less crippled versions
fedora_multimedia_packages=(
    'libva'
    'mesa-dri-drivers'
    'mesa-filesystem'
    'mesa-libEGL'
    'mesa-libGL'
    'mesa-libgbm'
    'mesa-va-drivers'
    'mesa-vulkan-drivers'
)
if [[ "$ARCH" == "x86_64" ]]; then
    fedora_multimedia_packages+=( 'libva-intel-media-driver' )
fi

dnf5 distro-sync -y --repo='fedora-multimedia' "${fedora_multimedia_packages[@]}"
dnf5 versionlock add "${fedora_multimedia_packages[@]}"

# Disable DKMS support in gnome-software
if [[ "$IMAGE_NAME" == "silverblue" ]]; then
    dnf5 remove -y \
        gnome-software-rpm-ostree
    dnf5 swap -y \
        --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        gnome-software gnome-software
    dnf5 versionlock add gnome-software
fi

# Install packages
/ctx/packages.sh /ctx/packages.json /ctx/packages.${ARCH}.json

# Install packages directly from GitHub
/ctx/github-release-install.sh --repository=sigstore/cosign --asset-filter=${ARCH} --download-only --output-dir=/tmp/github-rpms
/ctx/github-release-install.sh --repository=smallstep/cli --asset-filter=${ARCH} --download-only --output-dir=/tmp/github-rpms
/ctx/github-release-install.sh --repository=twpayne/chezmoi --asset-filter=${ARCH} --download-only --output-dir=/tmp/github-rpms

dnf5 install -y \
    /tmp/github-rpms/*.rpm

# Install git-credential-manager
# https://github.com/git-ecosystem/git-credential-manager
# no aarch64 support for gcm
if [[ "$ARCH" == "x86_64" ]]; then
    GCM_VERSION=2.6.1
    mkdir /tmp/gcm
    curl -sLo /tmp/gcm/gcm-linux.tar.gz https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_${ARCH_ALT}.${GCM_VERSION}.tar.gz
    tar -C /tmp/gcm -xf /tmp/gcm/gcm-linux.tar.gz
    mkdir /usr/lib/gcm
    cp /tmp/gcm/git-credential-manager /tmp/gcm/libHarfBuzzSharp.so /tmp/gcm/libSkiaSharp.so /usr/lib/gcm/
fi

# Install eza
# https://github.com/eza-community/eza
# official package falls behind quickly with rapid development and dep changes
EZA_VERSION="0.20.24"
EZA_TMPDIR=$(mktemp --directory /tmp/eza-XXXXXXXX)
curl -Lo ${EZA_TMPDIR}/eza.tar.gz https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${ARCH}-unknown-linux-gnu.tar.gz
curl -Lo ${EZA_TMPDIR}/man.tar.gz https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/man-${EZA_VERSION}.tar.gz
curl -Lo ${EZA_TMPDIR}/completions.tar.gz https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/completions-${EZA_VERSION}.tar.gz
tar -C ${EZA_TMPDIR} -xvf ${EZA_TMPDIR}/eza.tar.gz
tar -C ${EZA_TMPDIR} -xvf ${EZA_TMPDIR}/man.tar.gz
tar -C ${EZA_TMPDIR} -xvf ${EZA_TMPDIR}/completions.tar.gz
cp ${EZA_TMPDIR}/eza /usr/bin/
cp ${EZA_TMPDIR}/target/man-${EZA_VERSION}/*.1 /usr/share/man/man1/
cp ${EZA_TMPDIR}/target/man-${EZA_VERSION}/*.5 /usr/share/man/man5/
cp ${EZA_TMPDIR}/target/completions-${EZA_VERSION}/eza /usr/share/bash-completion/completions/
cp ${EZA_TMPDIR}/target/completions-${EZA_VERSION}/_eza /usr/share/zsh/site-functions/

# Install extra fonts
# MesloLGS NF (used for p10k)
mkdir -p /usr/share/fonts/meslolgs-nf
curl --output-dir /usr/share/fonts/meslolgs-nf -sLo "MesloLGS-NF-Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl --output-dir /usr/share/fonts/meslolgs-nf -sLo "MesloLGS-NF-Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl --output-dir /usr/share/fonts/meslolgs-nf -sLo "MesloLGS-NF-Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl --output-dir /usr/share/fonts/meslolgs-nf -sLo "MesloLGS-NF-Bold-Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache --system-only --really-force --verbose

# run any install scripts for image variants
if [ -f "/ctx/${IMAGE_VARIANT}/install.sh" ]; then
    "/ctx/${IMAGE_VARIANT}/install.sh"
fi

# install any packages from packages.json
if [ -f "/ctx/${IMAGE_VARIANT}/packages.json" ]; then
    /ctx/packages.sh /ctx/"${IMAGE_VARIANT}"/packages.json
fi
