#!/usr/bin/bash

set -oeux pipefail

# https://tim.siosm.fr/blog/2023/12/22/dont-change-defaut-login-shell/
rm -f /usr/bin/chsh /usr/bin/lchsh

# copy any shared sys files
if [[ -d /ctx/"${IMAGE_VARIANT}"/system_files/shared ]]; then
    rsync -rvK /ctx/"${IMAGE_VARIANT}"/system_files/shared/ /
fi

# copy any spin specific files, eg silverblue
if [[ -d "/ctx/${IMAGE_VARIANT}/system_files/${IMAGE_NAME}" ]]; then
    rsync -rvK "/ctx/${IMAGE_VARIANT}/system_files/${IMAGE_NAME}"/ /
fi

# run any pre-install scripts for image variants
if [ -f "/ctx/${IMAGE_VARIANT}/pre-install.sh" ]; then
    "/ctx/${IMAGE_VARIANT}/pre-install.sh"
fi
