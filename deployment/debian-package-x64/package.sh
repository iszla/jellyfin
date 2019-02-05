#!/usr/bin/env bash

source ../common.build.sh

WORKDIR="$( pwd )"
VERSION="$( grep '^jellyfin' ${WORKDIR}/pkg-src/changelog | head -1 | awk -F '[()]' '{ print $2 }' )"

package_temporary_dir="${WORKDIR}/pkg-dist-tmp"
output_dir="${WORKDIR}/pkg-dist"
current_user="$( whoami )"
image_name="jellyfin-debian-build"

# Determine if sudo should be used for Docker
if [[ ! -z $(id -Gn | grep -q 'docker') ]] \
  && [[ ! ${EUID:-1000} -eq 0 ]] \
  && [[ ! ${USER} == "root" ]] \
  && [[ ! -z $( echo "${OSTYPE}" | grep -q "darwin" ) ]]; then
    docker_sudo="sudo"
else
    docker_sudo=""
fi

# Set up the build environment Docker image
${docker_sudo} docker build ../.. -t "${image_name}" -f ./Dockerfile
# Build the DEBs and copy out to ${package_temporary_dir}
${docker_sudo} docker run --rm -v "${package_temporary_dir}:/dist" "${image_name}"
# Correct ownership on the DEBs (as current user, then as root if that fails)
chown -R "${current_user}" "${package_temporary_dir}" &>/dev/null \
  || sudo chown -R "${current_user}" "${package_temporary_dir}" &>/dev/null
# Move the DEBs to the output directory
mkdir -p "${output_dir}"
mv "${package_temporary_dir}"/deb/* "${output_dir}"
