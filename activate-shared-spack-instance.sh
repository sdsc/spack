#!/usr/bin/env bash
#
# Activate a shared Spack instance in your local ~/.spack configuration(s).

declare -xr SHARED_SPACK_VERSION='0.21.2'
declare -xr SHARED_SPACK_INSTANCE_NAME='cpu'
declare -xr SHARED_SPACK_INSTANCE_VERSION='dev'
declare -xr SHARED_SPACK_ROOT="/cm/shared/apps/spack/${SHARED_SPACK_VERSION}/${SHARED_SPACK_INSTANCE_NAME}/${SHARED_SPACK_INSTANCE_VERSION}"

declare -xr LOCAL_SPACK_NAMESPACE="${USER}"
declare -xr LOCAL_SPACK_TMPDIR='/tmp'
declare -xr LOCAL_SPACK_ROOT="${HOME}/.spack/${SHARED_SPACK_VERSION}/${SHARED_SPACK_INSTANCE_NAME}/${SHARED_SPACK_INSTANCE_VERSION}"

. "${SHARED_SPACK_ROOT}/share/spack/setup-env.sh"
module use "${SHARED_SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module use "${LOCAL_SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"

alias spack="spack --config-scope ${LOCAL_SPACK_ROOT}/etc/spack"
