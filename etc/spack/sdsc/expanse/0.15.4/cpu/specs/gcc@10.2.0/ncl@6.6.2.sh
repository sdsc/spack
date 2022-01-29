#!/usr/bin/env bash
# real 2029.96

#SBATCH --job-name=ncl@6.6.2
#SBATCH --account=use300
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=01:00:00
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

# Cannot set +gdal; try again with new concretizer
# ==> Error: Cannot depend on 'libszip@2.1.1%gcc@10.2.0 cflags="-O2 -march=native" cxxflags="-O2 -march=native" fflags="-O2 -march=native"  arch=linux-centos8-zen2' twice

# Now also getting with new ^python dep
# ==> Error: Detected uninstalled dependencies for tar: {'libiconv'}
# ==> Error: Cannot proceed with tar: 1 uninstalled dependency: libiconv
declare -xr SPACK_PACKAGE='ncl@6.6.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~gdal ~hdf4 +openmp +triangle +udunits2'
declare -xr SPACK_DEPENDENCIES="^esmf@7.1.0r/$(spack find --format '{hash:7}' esmf@7.1.0r % ${SPACK_COMPILER} ~mpi) ^python@3.8.5/$(spack find --format '{hash:7}' python@3.8.5 % ${SPACK_COMPILER})"

#"^netcdf-c@4.7.4/$(spack find --format '{hash:7}' netcdf-c@4.7.4 % ${SPACK_COMPILER} ~mpi)"

#"^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} ~mpi)"

#"^gdal@2.4.4/$(spack find --format '{hash:7}' gdal@2.4.4 % ${SPACK_COMPILER}) ^esmf@7.1.0r/$(spack find --format '{hash:7}' esmf@7.1.0r % ${SPACK_COMPILER} ~mpi)"

#"^netcdf-c@4.7.4/$(spack find --format '{hash:7}' netcdf-c@4.7.4 % ${SPACK_COMPILER} ~mpi) ^esmf@7.1.0r/$(spack find --format '{hash:7}' esmf@7.1.0r % ${SPACK_COMPILER} ~mpi) ^python@3.8.5/$(spack find --format '{hash:7}' python@3.8.5 % ${SPACK_COMPILER})"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'raja@0.12.1.sh'

sleep 60
