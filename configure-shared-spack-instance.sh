#!/usr/bin/env bash
#
# Configure a shared Spack instance in your local ~/.spack directory.

declare -xr SHARED_SPACK_VERSION='0.17.3'
declare -xr SHARED_SPACK_INSTANCE_NAME='cpu'
declare -xr SHARED_SPACK_INSTANCE_VERSION='b'
declare -xr SHARED_SPACK_ROOT="/cm/shared/apps/spack/${SHARED_SPACK_VERSION}/${SHARED_SPACK_INSTANCE_NAME}/${SHARED_SPACK_INSTANCE_VERSION}"

declare -xr LOCAL_SPACK_NAMESPACE="${USER}"
declare -xr LOCAL_SPACK_TMPDIR='/tmp'
declare -xr LOCAL_SPACK_ROOT="${HOME}/.spack/${SHARED_SPACK_VERSION}/${SHARED_SPACK_INSTANCE_NAME}/${SHARED_SPACK_INSTANCE_VERSION}/${SHARED_SPACK_USER}"

module reset
module list
. "${SHARED_SPACK_ROOT}/share/spack/setup-env.sh"
printenv

mkdir -p "${LOCAL_SPACK_ROOT}"

mkdir -p "${LOCAL_SPACK_ROOT}/var/spack/repos/${LOCAL_SPACK_NAMESPACE}/packages"
tee -a "${LOCAL_SPACK_ROOT}/var/spack/repos/${LOCAL_SPACK_NAMESPACE}/repo.yaml" << EOF
repo:
  namespace: ${LOCAL_SPACK_NAMESPACE}
EOF

mkdir -p "${LOCAL_SPACK_ROOT}/var/spack/stage"
mkdir -p "${LOCAL_SPACK_ROOT}/var/spack/cache"
mkdir -p "${LOCAL_SPACK_ROOT}/share/spack/modules"
mkdir -p "${LOCAL_SPACK_ROOT}/share/spack/lmod"
mkdir -p "${LOCAL_SPACK_ROOT}/opt/spack"

architecture='${ARCHITECTURE}'
compilername='${COMPILERNAME}'
compilerver='${COMPILERVER}'
package='${PACKAGE}'
version='${VERSION}'
hash='${HASH}'

mkdir -p  "${LOCAL_SPACK_ROOT}/etc/spack"
tee -a "${LOCAL_SPACK_ROOT}/config.yaml" << EOF
config:
  install_tree: 
    root: ${LOCAL_SPACK_ROOT}opt/spack
    projections:
      all: ${architecture}/${compilername}-${compilerver}/${package}-${version}-${hash}
  template_dirs:
    - ${SHARED_SPACK_ROOT}/share/spack/templates
  module_roots:
    tcl: ${LOCAL_SPACK_ROOT}share/spack/modules
    lmod: ${LOCAL_SPACK_ROOT}share/spack/lmod
  build_stage:
    - ${LOCAL_SPACK_ROOT}var/spack/stage
    - ${LOCAL_SPACK_TMPDIR}/${USER}/spack-stage
  source_cache: ${LOCAL_SPACK_ROOT}var/spack/cache
  misc_cache: ~/.spack/cache
  connect_timeout: 10
  verify_ssl: true
  suppress_gpg_warnings: false
  install_missing_compilers: false
  checksum: true
  dirty: false
  build_language: C
  locks: true
  build_jobs: 1
  ccache: false
  db_lock_timeout: 3
  package_lock_timeout: null
  shared_linking: 'rpath'
  allow_sgid: true
EOF

tee -a "${LOCAL_SPACK_ROOT}/repos.yaml" << EOF
repos:
  - ${LOCAL_SPACK_ROOT}var/spack/repos/${LOCAL_SPACK_NAMESPACE}
EOF

tee -a "${LOCAL_SPACK_ROOT}/upstreams.yaml" << EOF
upstreams:
  spack-instance-1:
    install_tree: ${SHARED_SPACK_ROOT}/opt/spack
EOF
