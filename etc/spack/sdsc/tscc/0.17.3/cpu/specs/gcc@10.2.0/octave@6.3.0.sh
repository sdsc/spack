#!/usr/bin/env bash

#SBATCH --job-name=octave@6.3.0
#SBATCH --account=sys200
#SBATCH --partition=hotel
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='tscc'

declare -xr SPACK_VERSION='0.17.3'
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

# still have a number of problems building octave with graphical 
# libraries such as gnuplot and imagemagick; to be revisited in the future
declare -xr SPACK_PACKAGE='octave@6.3.0'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+arpack +curl +fftw ~fltk ~fontconfig ~freetype ~gl2ps +glpk ~gnuplot +hdf5 +jdk ~llvm ~magick ~opengl +qhull +qrupdate ~qscintilla ~qt +readline +suitesparse +zlib'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.17/$(spack find --format '{hash:7}' openblas@0.3.17 % ${SPACK_COMPILER} ~ilp64 threads=none) ^arpack-ng@3.8.0/$(spack find --format '{hash:7}' arpack-ng@3.8.0 % ${SPACK_COMPILER} ~mpi) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^glpk@4.65/$(spack find --format '{hash:7}' glpk@4.65 % ${SPACK_COMPILER} +gmp) ^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} ~mpi) ^openjdk@11.0.12_7/$(spack find --format '{hash:7}' openjdk@11.0.12_7 % ${SPACK_COMPILER}) ^qhull@2020.2/$(spack find --format '{hash:7}' qhull@2020.2 % ${SPACK_COMPILER}) ^suite-sparse@5.10.1/$(spack find --format '{hash:7}' suite-sparse@5.10.1 % ${SPACK_COMPILER} ~openmp)"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'esmf@8.1.1.sh'

sleep 20
