#!/usr/bin/bash
set -eo pipefail
if [[ -z ${project_root} ]]; then
    project_root=$(git rev-parse --show-toplevel)
fi
if [[ -z ${git_branch} ]]; then
    git_branch=$(git branch --show-current)
fi

# Get Inputs
target=$1
image=$2

# Set image/target/version based on inputs
# shellcheck disable=SC2154,SC1091
. "${project_root}/just_scripts/get-defaults.sh"

# Get info
container_mgr=$(just _container_mgr)
tag=$(just _tag "${image}")

if [[ ${image} =~ "gnome" ]]; then
    base_image="silverblue"
elif [[ ${image} =~ "cosmic" ]]; then
    base_image="cosmic"
else
    base_image="kinoite"
fi

if [[ ${target} =~ "nvidia" ]]; then
    flavor="nvidia"
else
    flavor="main"
fi

# Set BASE_IMAGE - COSMIC uses official Fedora image, others use ublue-os
if [[ ${base_image} == "cosmic" ]]; then
    base_image_url="quay.io/fedora-ostree-desktops/cosmic-atomic:${latest}"
else
    base_image_url="ghcr.io/ublue-os/${base_image}-${flavor}:${latest}"
fi

# Build Image
$container_mgr build -f Containerfile \
    --build-arg="IMAGE_NAME=${tag}" \
    --build-arg="BASE_IMAGE_NAME=${base_image}" \
    --build-arg="BASE_IMAGE=${base_image_url}" \
    --build-arg="KERNEL_FLAVOR=bazzite" \
    --build-arg="SOURCE_IMAGE=${base_image}-${flavor}" \
    --build-arg="FEDORA_VERSION=${latest}" \
    --target="${target}" \
    --tag localhost/"${tag}:${latest}-${git_branch}" \
    "${project_root}"
