#!/usr/bin/bash

set -oeux pipefail

# Alternatives cannot create symlinks on its own during a container build
ln -sf /usr/bin/step-cli /etc/alternatives/step && ln -sf /etc/alternatives/step /usr/bin/step

ln -sf /usr/lib/gcm/git-credential-manager /usr/bin/git-credential-manager

# rbw completions must be manually generated
/usr/bin/rbw gen-completions bash > /usr/share/bash-completion/completions/rbw
/usr/bin/rbw gen-completions zsh > /usr/share/zsh/site-functions/_rbw

# Step CLI RPM does not create zsh completions
/usr/bin/step-cli completion zsh > /usr/share/zsh/site-functions/_step

ln -s "/usr/share/fonts/google-noto-sans-cjk-fonts" "/usr/share/fonts/noto-cjk" 

# run any post-install scripts for image variants
if [ -f "/ctx/${IMAGE_VARIANT}/post-install.sh" ]; then
    "/ctx/${IMAGE_VARIANT}/post-install.sh"
fi

# use CoreOS' generator for emergency/rescue boot
# see detail: https://github.com/ublue-os/main/issues/653
CSFG=/usr/lib/systemd/system-generators/coreos-sulogin-force-generator
curl -sSLo ${CSFG} https://raw.githubusercontent.com/coreos/fedora-coreos-config/refs/heads/stable/overlay.d/05core/usr/lib/systemd/system-generators/coreos-sulogin-force-generator
chmod +x ${CSFG}

/ctx/build-initramfs.sh
