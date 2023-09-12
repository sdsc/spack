#!/usr/bin/env bash

#SBATCH --job-name=pexsi@0.10.2
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


# unsatisfiable, conflicts are:
#  condition(3194)
# dependency_type(3194,"build")
# imposed_constraint(3194,"version_satisfies","superlu-dist","5.1.2:5.3")
# no version satisfies the given constraints
# node("superlu-dist")
# root("pexsi")
#  version("superlu-dist","5.3.0")
#  version_satisfies("pexsi","0.10.2")
#  version_satisfies("pexsi","0.10.2:","0.10.2")

# also requires 32-bit superlu-dist?
# >> 28    superlu_dist_internal_complex.cpp:566:42: error: cannot convert 'int
#           _t*' {aka 'long long int*'} to 'PEXSI::Int*' {aka 'int*'} in initial
#           ization


declare -xr SPACK_PACKAGE='pexsi@0.10.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+fortran'
declare -xr SPACK_DEPENDENCIES="^parmetis@4.0.3/$(spack find --format '{hash:7}' parmetis@4.0.3 % ${SPACK_COMPILER} ^openmpi@4.1.3) ^superlu-dist@5.3.0/$(spack find --format '{hash:7}' superlu-dist@5.3.0 % ${SPACK_COMPILER} ~int64 ^openmpi@4.1.3)"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'sirius@7.2.7.sh'

sleep 30
