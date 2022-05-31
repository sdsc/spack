#!/usr/bin/env bash

#SBATCH --job-name=py-scikit-image@0.14.2
#SBATCH --account=use300
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.15.4'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR="${HOME}/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

declare -xr SLURM_JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr SLURM_JOB_MD5SUM="$(md5sum ${SLURM_JOB_SCRIPT})"

declare -xr SCHEDULER_MODULE='slurm/expanse/20.02.3'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

# Remove +pyexpt variant on python as a fix? Do we really need it? Or create custom sdsc expat package with ~libbsd?
#==> Error: Cannot depend on 'libbsd@0.10.0%gcc@10.2.0 cflags="-O2 -march=native" cxxflags="-O2 -march=native" fflags="-O2 -march=native"  arch=linux-centos8-zen2' twice
# https://github.com/spack/spack/commit/f24398cde6902ae7871d7bd1992a0e1a08c47ab0#diff-17bd1a5eb144733789e892fe6fb2f8f4c0f0bb31155d5793e731f1f9fd5bb50a
# we could also set ~diagnostics on py-dask and then everything should concretize correctly with only ^py-matplotlib
declare -xr SPACK_PACKAGE='py-scikit-image@0.14.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS=''
declare -xr SPACK_DEPENDENCIES="^py-dask@2.16.0/$(spack find --format '{hash:7}' py-dask@2.16.0 % ${SPACK_COMPILER}) ^py-matplotlib@3.3.2/$(spack find --format '{hash:7}' py-matplotlib@3.3.2 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'arpack-ng@3.7.0.sh'

sleep 60
