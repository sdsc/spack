#!/usr/bin/env bash

#SBATCH --job-name=fftw@3.3.10-omp
#SBATCH --account=use300
#SBATCH --reservation=root_73
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

declare -xr SCHEDULER_MODULE='slurm/expanse/23.02.7'
declare -xr SPACK_MODULE='cpu/0.17.3b'
declare -xr COMPILER_MODULE='gcc/10.2.0'
declare -xr MPI_MODULE='mvapich2/2.3.7'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module load "${SPACK_MODULE}"
module load "${COMPILER_MODULE}"
module load "${MPI_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

declare -xr SPACK_PACKAGE='fftw@3.3.10'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_FLAGS="cflags=-I${MVAPICH2HOME}/include ldflags=-L${MVAPICH2HOME}/lib"
declare -xr SPACK_VARIANTS='+mpi +openmp ~pfft_patches'
declare -xr SPACK_DEPENDENCIES="^mvapich2@2.3.7/$(spack find --format '{hash:7}' mvapich2@2.3.7 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_FLAGS} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types fftw@3.3.10 % gcc@10.2.0 cflags=-I${MVAPICH2HOME}/include ldflags=-L${MVAPICH2HOME}/lib +mpi +openmp ~pfft_patches ^mvapich2@2.3.7/$(spack find --format '{hash:7}' mvapich2@2.3.7 % ${SPACK_COMPILER}) 
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all fftw@3.3.10 % gcc@10.2.0 cflags=-I${MVAPICH2HOME}/include ldflags=-L${MVAPICH2HOME}/lib +mpi +openmp ~pfft_patches ^mvapich2@2.3.7/$(spack find --format '{hash:7}' mvapich2@2.3.7 % ${SPACK_COMPILER})
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'hdf5@1.10.7.sh'

sleep 30
