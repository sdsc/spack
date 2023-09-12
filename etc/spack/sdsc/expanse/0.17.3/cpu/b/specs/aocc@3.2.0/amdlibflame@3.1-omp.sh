#!/usr/bin/env bash

#SBATCH --job-name=amdlibflame@3.1-omp
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr LOCAL_SCRATCH_DIR="/scratch/${USER}/job_${SLURM_JOB_ID}"
declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_VERSION='b'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}/${SPACK_INSTANCE_VERSION}"

declare -xr SLURM_JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr SLURM_JOB_MD5SUM="$(md5sum ${SLURM_JOB_SCRIPT})"

declare -xr SCHEDULER_MODULE='slurm'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

#==> Error: amdlibflame@3.1%aocc@3.2.0~debug~ilp64+lapack2flame+shared+static threads=openmp is unsatisfiable, conflicts are:
#  A conflict was triggered
#  condition(28)
#  condition(33)
#  condition(34)
#  conflict("amdlibflame",33,34)
#  root("amdlibflame")
#  variant_condition(28,"amdlibflame","threads")
#  variant_set("amdlibflame","threads","openmp")
#
#Input spec
#--------------------------------
#amdlibflame@3.1%aocc@3.2.0~debug~ilp64+lapack2flame+shared+static threads=openmp

declare -xr SPACK_PACKAGE='amdlibflame@3.1'
declare -xr SPACK_COMPILER='aocc@3.2.0'
declare -xr SPACK_VARIANTS='~debug ~ilp64 +lapack2flame +shared +static' #threads=none'
declare -xr SPACK_DEPENDENCIES="^amdblis@3.1/$(spack find --format '{hash:7}' amdblis@3.1 % ${SPACK_COMPILER} ~ilp64 threads=openmp)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'gsl@2.7.sh'

sleep 30
