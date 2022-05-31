#!/usr/bin/env bash

#SBATCH --job-name=openmm@7.4.1
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


#1 error found in build log:
#     43      cmake_modules/FindOpenCL.cmake:86 (find_package_handle_standard_ar
#           gs)
#     44      CMakeLists.txt:334 (FIND_PACKAGE)
#     45    This warning is for project developers.  Use -Wno-dev to suppress it
#           .
#     46    
#     47    -- Found OPENCL: /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/s
#           pack/linux-centos8-skylake_avx512/gcc-8.4.0/cuda-10.2.89-yp465scb7fv
#           ymjopcpf3bose34d2gkng/lib64/libOpenCL.so
#     48    -- Configuring done
#  >> 49    CMake Error: The following variables are used in this project, but t
#           hey are set to NOTFOUND.
#     50    Please set them or make sure they are set and tested correctly in th
#           e CMake files:
#     51    CUDA_CUDA_LIBRARY (ADVANCED)
#     52        linked by target "OpenMMCUDA" in directory /tmp/mkandes/spack-st
#           age/spack-stage-openmm-7.4.1-oebtrjt53jv7bgs3kszidt32gxqtxmb2/spack-
#           src/platforms/cuda/sharedTarget
#     53    
#     54    -- Generating done
#     55    CMake Generate step failed.  Build files cannot be regenerated corre
#           ctly.

declare -xr SPACK_PACKAGE='openmm@7.4.1'
declare -xr SPACK_COMPILER='gcc@8.4.0'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=70'
declare -xr SPACK_DEPENDENCIES="^cuda@10.2.89 ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} ~mpi ~openmp) ^py-numpy@1.19.2/$(spack find --format '{hash:7}' py-numpy@1.19.2 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types openmm@7.4.1 % gcc@8.4.0 +cuda cuda_arch=70 "^cuda@10.2.89 ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} ~mpi ~openmp) ^py-numpy@1.19.2/$(spack find --format '{hash:7}' py-numpy@1.19.2 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all openmm@7.4.1 % gcc@8.4.0 +cuda cuda_arch=70 "^cuda@10.2.89 ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} ~mpi ~openmp) ^py-numpy@1.19.2/$(spack find --format '{hash:7}' py-numpy@1.19.2 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
