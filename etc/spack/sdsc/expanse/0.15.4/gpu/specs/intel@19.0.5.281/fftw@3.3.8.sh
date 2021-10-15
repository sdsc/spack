#!/usr/bin/env bash

#SBATCH --job-name=fftw@3.3.8
#SBATCH --account=use300
#SBATCH --partition=gpu-debug
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=93G
#SBATCH --gpus=1
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.15.4'
declare -xr SPACK_INSTANCE_NAME='gpu'
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

# THE ISSUE BELOW was resolved by appending cflags=-gcc-sys
# https://www.intel.com/content/www/us/en/develop/documentation/cpp-compiler-developer-guide-and-reference/top/compiler-reference/compiler-options/compiler-option-details/preprocessor-options/gcc-gcc-sys.html
#
#==> Installing fftw
#==> No binary for fftw found: installing from source
#==> Using cached archive: /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/var/spack/cache/_source-cache/archive/61/6113262f6e92c5bd474f2875fa1b01054c4ad5040f6b0da7c03c
#98821d9ae303.tar.gz
#==> fftw: Executing phase: 'autoreconf'
#==> fftw: Executing phase: 'configure'
#==> Error: ProcessError: Command exited with status 1:
#    '../configure' '--prefix=/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-cascadelake/intel-19.0.5.281/fftw-3.3.8-rg4e3pvpzhhu7rvmlihgeechop
#225mae' '--enable-shared' '--enable-threads' '--enable-sse2' '--enable-avx' '--enable-avx2' '--enable-avx512' '--disable-avx-128-fma' '--disable-kcvi' '--disable-vsx
#' '--disable-neon' '--enable-fma'
#
#1 error found in build log:
#     182    checking for ptrdiff_t... no
#     183    checking for uintptr_t... no
#     184    checking size of void *... 0
#     185    checking size of float... 0
#     186    checking size of double... 0
#     187    checking size of fftw_r2r_kind... 0
#  >> 188    configure: error: sizeof(fftw_r2r_kind) test failed
#
#See build log for details:
#  /tmp/mkandes/spack-stage/spack-stage-fftw-3.3.8-rg4e3pvpzhhu7rvmlihgeechop225mae/spack-build-out.txt

declare -xr INTEL_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='fftw@3.3.8'
declare -xr SPACK_COMPILER='intel@19.0.5.281'
declare -xr SPACK_VARIANTS='~mpi ~openmp ~pfft_patches'
declare -xr SPACK_DEPENDENCIES='cflags=-gcc-sys'
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'fftw@3.3.8-omp.sh'

sleep 60
