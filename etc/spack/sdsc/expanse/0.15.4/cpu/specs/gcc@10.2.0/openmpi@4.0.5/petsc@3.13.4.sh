#!/usr/bin/env bash
# real 1214.82

#SBATCH --job-name=petsc@3.13.4
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

# ==> Error: Cannot depend on 'hwloc@1.11.11 twice
declare -xr SPACK_PACKAGE='petsc@3.13.4'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~X ~batch ~cgns ~complex ~cuda ~debug +double ~exodusii ~fftw ~giflib +hdf5 +hypre +int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~moab ~mpfr +mpi ~mumps ~p4est ~random123 ~saws +shared +suite-sparse +superlu-dist ~trilinos ~valgrind'
declare -xr SPACK_DEPENDENCIES="^python@3.8.5/$(spack find --format '{hash:7}' python@3.8.5 % ${SPACK_COMPILER}) ^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^parmetis@4.0.3/$(spack find --format '{hash:7}' parmetis@4.0.3 % ${SPACK_COMPILER} +int64 ^openmpi@4.0.5)"

#"^python@3.8.5/y47j26d ^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} +mpi ^openmpi@4.0.5) ^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.0.5) ^hypre@2.18.2/$(spack find --format '{hash:7}' hypre@2.18.2 % ${SPACK_COMPILER} +int64 +mpi ^openmpi@4.0.5) ^parmetis@4.0.3/$(spack find --format '{hash:7}' parmetis@4.0.3 % ${SPACK_COMPILER} +int64 ^openmpi@4.0.5) ^suite-sparse@5.7.2/$(spack find --format '{hash:7}' suite-sparse@5.7.2 % ${SPACK_COMPILER}) ^superlu-dist@6.3.0/$(spack find --format '{hash:7}' superlu-dist@6.3.0 % ${SPACK_COMPILER} +int64 ^openmpi@4.0.5)"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'petsc@3.13.4-complex.sh'

sleep 60
