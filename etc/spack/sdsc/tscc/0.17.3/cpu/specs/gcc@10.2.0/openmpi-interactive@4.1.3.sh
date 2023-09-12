#!/usr/bin/env bash

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='tscc'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"


echo "${UNIX_TIME}"
echo ""

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

# the +thread_multiple variant may no longer be working correctly; must 
# leave explicit setting out or run into unsat conditions
declare -xr SPACK_PACKAGE='openmpi@4.1.3'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=ucx schedulers=slurm'
declare -xr SPACK_DEPENDENCIES="^lustre@2.15.2 ^slurm@22.05.8 ^rdma-core@41.0 ^ucx@1.10.1/$(spack find --format '{hash:7}' ucx@1.10.1 % gcc@11.2.0)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types openmpi@4.1.3 % gcc@10.2.0 ~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=ucx schedulers=slurm ^lustre@2.15.2 ^slurm@22.05.8 ^rdma-core@41.0 "^ucx@1.10.1/$(spack find --format '{hash:7}' ucx@1.10.1 % gcc@11.2.0)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs 8 --fail-fast --yes-to-all openmpi@4.1.3 % gcc@10.2.0 ~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=ucx schedulers=slurm ^lustre@2.15.2 ^slurm@22.05.8 ^rdma-core@41.0 "^ucx@1.10.1/$(spack find --format '{hash:7}' ucx@1.10.1 % gcc@11.2.0)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y
