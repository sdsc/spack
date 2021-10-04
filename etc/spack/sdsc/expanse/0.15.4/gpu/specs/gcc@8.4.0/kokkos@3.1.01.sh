#!/usr/bin/env bash

#SBATCH --job-name=kokkos@3.1.01
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


#6     -- Check for working CXX compiler: /home/mkandes/cm/shared/apps/spac
#           k/0.15.4/gpu/lib/spack/env/gcc/g++ - skipped
#     7     -- Detecting CXX compile features
#     8     -- Detecting CXX compile features - done
#     9     -- Setting policy CMP0074 to use <Package>_ROOT variables
#     10    -- The project name is: Kokkos
#     11    -- Using -std=c++11 for C++11 standard as feature
#  >> 12    CMake Error at cmake/kokkos_test_cxx_std.cmake:109 (MESSAGE):
#     13      Invalid compiler for CUDA.  The compiler must be nvcc_wrapper or C
#           lang, but
#     14      compiler ID was GNU
#     15    Call Stack (most recent call first):
#     16      cmake/kokkos_tribits.cmake:180 (INCLUDE)
#     17      CMakeLists.txt:156 (KOKKOS_SETUP_BUILD_ENVIRONMENT)
#     18    


declare -xr SPACK_PACKAGE='kokkos@3.1.01'
declare -xr SPACK_COMPILER='gcc@8.4.0'
declare -xr SPACK_VARIANTS='~aggressive_vectorization ~compiler_warnings +cuda +cuda_lambda ~cuda_ldg_intrinsic ~cuda_relocatable_device_code +cuda_uvm ~debug ~debug_bounds_check ~debug_dualview_modify_check ~deprecated_code ~examples ~explicit_instantiation ~hip ~hpx ~hpx_async_dispatch ~hwloc ~memkind ~numactl ~openmp +pic +profiling ~profiling_load_print ~pthread ~qthread +serial +shared ~tests~wrapper cuda_arch=70'
declare -xr SPACK_DEPENDENCIES='^cuda@10.2.89'
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types kokkos@3.1.01 % gcc@8.4.0 ~aggressive_vectorization ~compiler_warnings +cuda +cuda_lambda ~cuda_ldg_intrinsic ~cuda_relocatable_device_code +cuda_uvm ~debug ~debug_bounds_check ~debug_dualview_modify_check ~deprecated_code ~examples ~explicit_instantiation ~hip ~hpx ~hpx_async_dispatch ~hwloc ~memkind ~numactl ~openmp +pic +profiling ~profiling_load_print ~pthread ~qthread +serial +shared ~tests~wrapper cuda_arch=70 ^cuda@10.2.89
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all kokkos@3.1.01 % gcc@8.4.0 ~aggressive_vectorization ~compiler_warnings +cuda +cuda_lambda ~cuda_ldg_intrinsic ~cuda_relocatable_device_code +cuda_uvm ~debug ~debug_bounds_check ~debug_dualview_modify_check ~deprecated_code ~examples ~explicit_instantiation ~hip ~hpx ~hpx_async_dispatch ~hwloc ~memkind ~numactl ~openmp +pic +profiling ~profiling_load_print ~pthread ~qthread +serial +shared ~tests~wrapper cuda_arch=70 ^cuda@10.2.89
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
