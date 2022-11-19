#!/usr/bin/env bash

#SBATCH --job-name=wrf@4.2
#SBATCH --account=use300
#SBATCH --reservation=root_63
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.2'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

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

declare -xr SPACK_PACKAGE='wrf@4.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='build_type=dm+sm compile_type=em_real nesting=basic +pnetcdf'
declare -xr SPACK_DEPENDENCIES="^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^parallel-netcdf@1.12.2/$(spack find --format '{hash:7}' parallel-netcdf@1.12.2 % ${SPACK_COMPILER} ^openmpi@4.1.3) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +mpi +parallel-netcdf ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types wrf@4.2 % gcc@10.2.0 build_type='dm+sm' compile_type=em_real nesting=basic +pnetcdf "^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^parallel-netcdf@1.12.2/$(spack find --format '{hash:7}' parallel-netcdf@1.12.2 % ${SPACK_COMPILER} ^openmpi@4.1.3) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all wrf@4.2 % gcc@10.2.0 build_type='dm+sm' compile_type=em_real nesting=basic +pnetcdf "^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^parallel-netcdf@1.12.2/$(spack find --format '{hash:7}' parallel-netcdf@1.12.2 % ${SPACK_COMPILER} ^openmpi@4.1.3) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'wps@4.2.sh'

sleep 60
