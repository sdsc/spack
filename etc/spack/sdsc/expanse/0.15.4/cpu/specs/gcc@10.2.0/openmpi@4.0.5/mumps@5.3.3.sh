#!/usr/bin/env bash

#SBATCH --job-name=mumps@5.3.3
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

# required for trilinos? no, doesn't look like it, but is default variant
# mumps requires scotch constrain a concrete spec scotch+esmumps~metis+mpi
# Twice dep problem; cannot install; try again later; maybe reduce +variants
# ==> Error: Cannot depend on 'hwloc@1.11.11 twice
# 
# Even after reducing +variants, problem still appeared with +int64 ...
# Error: Rank mismatch between actual argument at (1) and actual argu
#            ment at (2) (scalar and rank-1)
declare -xr SPACK_PACKAGE='mumps@5.3.3'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+complex +double +float ~int64 ~metis +mpi ~parmetis ~ptscotch ~scotch +shared'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^netlib-scalapack@2.1.0/$(spack find --format '{hash:7}' netlib-scalapack@2.1.0 % ${SPACK_COMPILER})"
#"^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^metis@5.1.0/$(spack find --format '{hash:7}' metis@5.1.0 % ${SPACK_COMPILER} +int64 +real64) ^parmetis@4.0.3/$(spack find --format '{hash:7}' parmetis@4.0.3 % ${SPACK_COMPILER} +int64) ^netlib-scalapack@2.1.0/$(spack find --format '{hash:7}' netlib-scalapack@2.1.0 % ${SPACK_COMPILER}) ^scotch@6.0.10/$(spack find --format '{hash:7}' scotch@6.0.10 % ${SPACK_COMPILER})"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
