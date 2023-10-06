#!/usr/bin/env bash
#
# Activate a shared Spack instance in your local ~/.spack configuration(s).

declare -xr SHARED_SPACK_VERSION='0.17.3'
declare -xr SHARED_SPACK_INSTANCE_NAME='gpu'
declare -xr SHARED_SPACK_INSTANCE_VERSION='b'
declare -xr SHARED_SPACK_ROOT="/cm/shared/apps/spack/${SHARED_SPACK_VERSION}/${SHARED_SPACK_INSTANCE_NAME}/${SHARED_SPACK_INSTANCE_VERSION}"

declare -xr LOCAL_SPACK_NAMESPACE="${USER}"
declare -xr LOCAL_SPACK_TMPDIR='/tmp'
declare -xr LOCAL_SPACK_ROOT="${HOME}/.spack/${SHARED_SPACK_VERSION}/${SHARED_SPACK_INSTANCE_NAME}/${SHARED_SPACK_INSTANCE_VERSION}/${SHARED_SPACK_USER}"

. "${SHARED_SPACK_ROOT}/share/spack/setup-env.sh"
module use "${LOCAL_SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64"

alias spack="spack --config-scope ${LOCAL_SPACK_ROOT}"
