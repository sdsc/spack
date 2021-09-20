#!/usr/bin/env bash
# real 514.44

#SBATCH --job-name=gdal@3.1.3
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

declare -xr SPACK_PACKAGE='gdal@3.1.3'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~armadillo ~cfitsio ~crypto ~cryptopp ~curl ~expat +geos ~gif ~grib ~hdf4 +hdf5 ~jasper ~java +jpeg ~kea ~libiconv ~libkml +liblzma +libtool +libz ~mdb +netcdf ~odbc ~opencl ~openjpeg ~pcre ~perl ~pg +png ~poppler +proj +python +qhull ~sosi +sqlite3 ~xerces ~xml2 ~zstd'
declare -xr SPACK_DEPENDENCIES="^geos@3.8.1/$(spack find --format '{hash:7}' geos@3.8.1 % ${SPACK_COMPILER} +python) ^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^netcdf-c@4.7.4/$(spack find --format '{hash:7}' netcdf-c@4.7.4 % ${SPACK_COMPILER} ~mpi)"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'gdal@2.4.4.sh'

sleep 60
