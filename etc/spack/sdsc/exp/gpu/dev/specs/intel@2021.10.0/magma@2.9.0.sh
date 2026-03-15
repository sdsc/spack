#!/usr/bin/env bash

#SBATCH --job-name=magma@2.9.0
#SBATCH --account=use300
#SBATCH --reservation=root_73
#SBATCH --clusters=expanse
#SBATCH --partition=ind-gpu-shared
#SBATCH --qos=gpu-unlim
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=92G
#SBATCH --gpus=1
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xir UNIX_TIME="$(date +'%s')"
declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"

declare -xr JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr JOB_SCRIPT_MD5="$(md5sum ${JOB_SCRIPT} | awk '{print $1}')"
declare -xr JOB_SCRIPT_SHA256="$(sha256sum ${JOB_SCRIPT} | awk '{print $1}')"
declare -xr JOB_SCRIPT_NUMBER_OF_LINES="$(wc -l ${JOB_SCRIPT} | awk '{print $1}')"

declare -xr SCHEDULER_NAME='slurm'
declare -xr SCHEDULER_MAJOR='23'
declare -xr SCHEDULER_MINOR='02'
declare -xr SCHEDULER_REVISION='7'
declare -xr SCHEDULER_VERSION="${SCHEDULER_MAJOR}.${SCHEDULER_MINOR}.${SCHEDULER_REVISION}"
declare -xr SCHEDULER_MODULE="${SCHEDULER_NAME}/${SLURM_CLUSTER_NAME}/${SCHEDULER_VERSION}"

declare -xr COMPILER_NAME='gcc'
declare -xr COMPILER_MAJOR='13'
declare -xr COMPILER_MINOR='3'
declare -xr COMPILER_REVISION='0'
declare -xr SPACK_SYSTEM_NAME='exp'
declare -xr COMPILER_VERSION="${COMPILER_MAJOR}.${COMPILER_MINOR}.${COMPILER_REVISION}"
declare -xr COMPILER_MODULE="${COMPILER_NAME}/${COMPILER_VERSION}"

declare -xr CUDA_NAME='cuda'
declare -xr CUDA_MAJOR='12'
declare -xr CUDA_MINOR='6'
declare -xr CUDA_REVISION='3'
declare -xr CUDA_VERSION="${CUDA_MAJOR}.${CUDA_MINOR}.${CUDA_REVISION}"
declare -xr CUDA_MODULE="${CUDA_NAME}/${CUDA_VERSION}"

declare -xr SPACK_MAJOR='0'
declare -xr SPACK_MINOR='21'
declare -xr SPACK_REVISION='2'
declare -xr SPACK_VERSION="${SPACK_MAJOR}.${SPACK_MINOR}.${SPACK_REVISION}"
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_VERSION='dev'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}/${SPACK_INSTANCE_VERSION}"

declare -xr TMPDIR="${SLURM_TMPDIR}/spack-stage"
declare -xr TMP="${TMPDIR}"

echo "${UNIX_TIME} ${LOCAL_TIME} ${SLURM_JOB_ID} ${JOB_SCRIPT_MD5} ${JOB_SCRIPT_SHA256} ${JOB_SCRIPT_NUMBER_OF_LINES} ${JOB_SCRIPT}"
cat  "${JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_MODULE}"
module load "${CUDA_MODULE}"
module list

declare -xr SPACK_PACKAGE='magma@2.9.0'
declare -xr SPACK_COMPILER='intel@2021.10.0'
declare -xr SPACK_VARIANTS='+cuda +fortran ~rocm +shared cuda_arch=70,80,90'
declare -xr SPACK_DEPENDENCIES="^cuda@12.6.3/$(spack find --format '{hash:7}' cuda@12.6.3 % ${SPACK_COMPILER}) ^intel-oneapi-mkl@2023.2.0/$(spack find --format '{hash:7}' intel-oneapi-mkl@2023.2.0 % ${SPACK_COMPILER} ~cluster ~ilp64 threads=none)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

export CUDATOOLKIT_HOME="${CUDA_ROOT}"
printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types --reuse "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

mkdir -p "${TMPDIR}"

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all --reuse "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

time -p spack mirror create --dependencies --directory "${HOME}/software/spack/caches/${SPACK_VERSION}/${SPACK_SYSTEM_NAME}/${SPACK_INSTANCE_NAME}/dev" "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack mirror create failed.'
  exit 1
fi

time -p spack buildcache push "${HOME}/software/spack/caches/${SPACK_VERSION}/${SPACK_SYSTEM_NAME}/${SPACK_INSTANCE_NAME}/dev" "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack buildcache push failed.'
  exit 1
fi
