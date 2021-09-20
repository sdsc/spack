#!/usr/bin/env bash
# real 734.07

#SBATCH --job-name=r@4.0.2
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

# Cannot set +rmath
# 1 error found in build log:
#     2447    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-r
#             -4.0.2-6d64d4jctyf3mpeqogghciieoi5znnqo/spack-src/tests'
#     2448    ==> [2021-03-29-12:45:47.986087] 'make' '-j128' 'install'
#     2449    make[1]: Entering directory '/tmp/mkandes/spack-stage/spack-stage-
#             r-4.0.2-6d64d4jctyf3mpeqogghciieoi5znnqo/spack-src/src/include'
#     2450    make[1]: 'Rmath.h' is up to date.
#     2451    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-r
#             -4.0.2-6d64d4jctyf3mpeqogghciieoi5znnqo/spack-src/src/include'
#     2452    mkdir -p -- /home/mkandes/cm/shared/apps/spack/0.15.4/cpu/opt/spac
#             k/linux-centos8-zen2/gcc-10.2.0/r-4.0.2-6d64d4jctyf3mpeqogghciieoi
#             5znnqo/include
#  >> 2453    cp: cannot create regular file '/home/mkandes/cm/shared/apps/spack
#             /0.15.4/cpu/opt/spack/linux-centos8-zen2/gcc-10.2.0/r-4.0.2-6d64d4
#             jctyf3mpeqogghciieoi5znnqo/include/Rmath.h': No such file or direc
#             tory
#     2454    make: *** [Makefile:154: install-header] Error 1
#     2455    make: *** Waiting for unfinished jobs.... 
declare -xr SPACK_PACKAGE='r@4.0.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~X +external-lapack ~memory_profiling ~rmath'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^python@3.8.5/$(spack find --format '{hash:7}' python@3.8.5 % ${SPACK_COMPILER})"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'julia@1.5.3.sh'

sleep 60
