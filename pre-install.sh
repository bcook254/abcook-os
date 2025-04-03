#!/usr/bin/bash

set -oeux pipefail

# https://tim.siosm.fr/blog/2023/12/22/dont-change-defaut-login-shell/
rm -f /usr/bin/chsh /usr/bin/lchsh

# copy any shared files
if [[ -d /ctx/system_files/shared ]]; then
    rsync -rvK /ctx/system_files/shared/ /
fi

# copy any image variant shared files, eg main, suface
if [[ -d /ctx/"${IMAGE_VARIANT}"/system_files/shared ]]; then
    rsync -rvK /ctx/"${IMAGE_VARIANT}"/system_files/shared/ /
fi

# copy any image variant spin specific files, eg main-silverblue, surface-kinoite
if [[ -d "/ctx/${IMAGE_VARIANT}/system_files/${IMAGE_NAME}" ]]; then
    rsync -rvK "/ctx/${IMAGE_VARIANT}/system_files/${IMAGE_NAME}"/ /
fi

# run any image variant pre-install scripts
if [ -f "/ctx/${IMAGE_VARIANT}/pre-install.sh" ]; then
    "/ctx/${IMAGE_VARIANT}/pre-install.sh"
fi
