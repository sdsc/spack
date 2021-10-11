#!/usr/bin/env bash

#SBATCH --job-name=netlib-lapack@3.8.0
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


#3 errors found in build log:
#     3     -- The Fortran compiler identification is Intel 19.1.2.20200623
#     4     -- The C compiler identification is Intel 19.1.2.20200623
#     5     -- Detecting Fortran compiler ABI info
#     6     -- Detecting Fortran compiler ABI info - failed
#     7     -- Check for working Fortran compiler: /home/mkandes/cm/shared/apps/
#           spack/0.15.4/gpu/lib/spack/env/intel/ifort
#     8     -- Check for working Fortran compiler: /home/mkandes/cm/shared/apps/
#           spack/0.15.4/gpu/lib/spack/env/intel/ifort - broken
#  >> 9     CMake Error at /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spa
#           ck/linux-centos8-cascadelake/intel-19.0.5.281/cmake-3.18.2-qtqxuiqm5
#           iiyzhdwgecwvwm7qt3rz7q5/share/cmake-3.18/Modules/CMakeTestFortranCom
#           piler.cmake:51 (message):
#     10      The Fortran compiler
#     11    
#     12        "/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/lib/spack/env/int
#           el/ifort"
#     13    
#     14      is not able to compile a simple test program.

declare -xr INTEL_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='netlib-lapack@3.8.0'
declare -xr SPACK_COMPILER='intel@19.0.5.281'
declare -xr SPACK_VARIANTS='~external-blas +lapacke +shared ~xblas'
declare -xr SPACK_DEPENDENCIES=''
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'intel-mkl@2020.3.279.sh'

sleep 60
