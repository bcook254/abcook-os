#!/usr/bin/bash

# A script to install an RPM from the latest Github release for a project.
# Maintained by the ublue-os project at https://github.com/ublue-os/main/blob/main/github-release-install.sh
# Maintained by bcook254 at https://github.com/bcook254/abcook-os/main/blob/main/github-release-install.sh
#
#   Copyright 2024 Universal Blue (https://universal-blue.org)
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

usage() {
  cat <<EOF
Usage: github-release-install.sh --repository <org/repo> --asset-filter <filter> [options]

Installs an RPM package from the latest GitHub release of a specified repository.

Required Arguments:
  --repository <org/repo>       The GitHub repository in 'organization/project' format.
  --asset-filter <filter>       A regex string to filter the RPM asset (e.g., 'x86_64' or 'f41\.aarch64').

Optional Arguments:
  --release-tag <tag>           A specific release tag (default: latest).
  --download-only               Download the RPM without installing it.
  --dry-run                     Only print the selected asset url to stdout.
  --output-dir <directory>      Specify the output directory for downloaded RPMs (default: current directory).
  --output-file <filename>      Rename the downloaded RPM file.
  --help, -h                    Show this help message and exit.

Example Usage:
  github-release-install.sh --repository wez/wezterm --asset-filter "fedora37\.x86_64"
  github-release-install.sh --repository twpayne/chezmoi --asset-filter aarch64 --download-only --output-dir /tmp

Maintained by:
  ublue-os: https://github.com/ublue-os/main/blob/main/github-release-install.sh
  bcook254: https://github.com/bcook254/abcook-os/main/blob/main/github-release-install.sh
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --asset-filter*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if not `=`
      ASSET_FILTER="${1#*=}"
      ;;
    --repository*)
      if [[ "$1" != *=* ]]; then shift; fi
      REPO="${1#*=}"
      ;;
    --release-tag*)
      if [[ "$1" != *=* ]]; then shift; fi
      TAG="tags/${1#*=}"
      ;;
    --download-only)
      DOWNLOAD_ONLY="true"
      ;;
    --dry-run)
      DRY_RUN="true"
      ;;
    --output-dir*)
      if [[ "$1" != *=* ]]; then shift; fi
      OUTPUT_DIR="${1#*=}"
      ;;
    --output-file*)
      if [[ "$1" != *=* ]]; then shift; fi
      OUTPUT_FILE="${1#*=}"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument '$1'\n"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ -z "${REPO}" ]; then
  usage
  exit 2
fi

if [ -z "${ASSET_FILTER}" ]; then
  usage
  exit 2
fi

TAG="${TAG:-latest}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"

set -ouex pipefail

API_JSON=$(mktemp /tmp/api-XXXXXXXX.json)
API="https://api.github.com/repos/${REPO}/releases/${TAG}"

# retry up to 5 times with 5 second delays for any error included HTTP 404 etc
if ! curl --fail --retry 5 --retry-delay 5 --retry-all-errors -sL ${API} -o ${API_JSON}; then
  exit 3
fi
RPM_URLS=($(cat ${API_JSON} |
  jq \
    -r \
    --arg asset_filter "${ASSET_FILTER}" \
    '.assets | sort_by(.created_at) | reverse | .[] | select(.name|test($asset_filter)) | select (.name|test("rpm$")) | .browser_download_url'))

if [ "${#RPM_URLS[@]}" -eq 0 ]; then
  echo "no rpm assets were found"
  exit 4
fi

# WARNING: in case of multiple matches, this only downloads/installs the first matched release
if [ ! -z ${DRY_RUN+x} ]; then
  echo "${RPM_URLS}"
elif [ ! -z ${DOWNLOAD_ONLY+x} ]; then
  download_args=(
    '--fail'
    '--retry' '5'
    '--retry-delay' '5'
    '--retry-all-errors'
    '-sL'
    '--output-dir' "${OUTPUT_DIR}"
    '--create-dirs'
  )

  if [ -z "${OUTPUT_FILE+x}" ]; then
    download_args+=( '-O' )
  else
    download_args+=( '-o' "${OUTPUT_FILE}" )
  fi

  curl ${download_args[@]} "${RPM_URLS}"
else
  echo "execute: dnf5 install -y \"${RPM_URLS}\""
  dnf5 -y install "${RPM_URLS}";
fi
