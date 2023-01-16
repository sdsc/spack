#!/usr/bin/env bash

#SBATCH --job-name=kokkos@3.4.01
#SBATCH --account=use300
##SBATCH --reservation=root_63
#SBATCH --partition=ind-gpu-shared
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

declare -xr SPACK_VERSION='0.17.2'
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_DIR="${HOME}/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

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

# +cuda_relocatable_device_code not working; would you need cuda +dev for static libraries to be installed? or is this in driver packages?
# >> 12    CMake Error at cmake/kokkos_enable_options.cmake:124 (MESSAGE):
#     13      Relocatable device code requires static libraries.

# multiple cuda_arch not working together? does KOKKOS not support multiple cuda_arch in same build?
#>> 13    CMake Error at cmake/kokkos_arch.cmake:383 (MESSAGE):
#     14      Multiple GPU architectures given! Already have VOLTA70, but trying
#            to add
#     15      AMPERE80.  If you are re-running CMake, try clearing the cache and
#            running
#     16      again

declare -xr SPACK_PACKAGE='kokkos@3.4.01'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~aggressive_vectorization ~compiler_warnings +cuda cuda_arch=70 ~cuda_constexpr ~cuda_lambda ~cuda_ldg_intrinsic ~cuda_relocatable_device_code ~cuda_uvm ~debug ~debug_bounds_check ~debug_dualview_modify_check ~deprecated_code ~examples ~explicit_instantiation ~hpx ~hpx_async_dispatch ~hwloc ~ipo ~memkind ~numactl ~openmp +pic +profiling ~profiling_load_print ~pthread ~qthread ~rocm +serial +shared ~sycl ~tests ~tuning +wrapper'
declare -xr SPACK_DEPENDENCIES="^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER}) ^kokkos-nvcc-wrapper ~mpi"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types kokkos@3.4.01 % gcc@10.2.0 ~aggressive_vectorization ~compiler_warnings +cuda cuda_arch=70 ~cuda_constexpr ~cuda_lambda ~cuda_ldg_intrinsic ~cuda_relocatable_device_code ~cuda_uvm ~debug ~debug_bounds_check ~debug_dualview_modify_check ~deprecated_code ~examples ~explicit_instantiation ~hpx ~hpx_async_dispatch ~hwloc ~ipo ~memkind ~numactl ~openmp +pic +profiling ~profiling_load_print ~pthread ~qthread ~rocm +serial +shared ~sycl ~tests ~tuning +wrapper "^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER}) ^kokkos-nvcc-wrapper ~mpi"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all kokkos@3.4.01 % gcc@10.2.0 ~aggressive_vectorization ~compiler_warnings +cuda cuda_arch=70 ~cuda_constexpr ~cuda_lambda ~cuda_ldg_intrinsic ~cuda_relocatable_device_code ~cuda_uvm ~debug ~debug_bounds_check ~debug_dualview_modify_check ~deprecated_code ~examples ~explicit_instantiation ~hpx ~hpx_async_dispatch ~hwloc ~ipo ~memkind ~numactl ~openmp +pic +profiling ~profiling_load_print ~pthread ~qthread ~rocm +serial +shared ~sycl ~tests ~tuning +wrapper "^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER}) ^kokkos-nvcc-wrapper ~mpi"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'cgal@5.0.3.sh'

sleep 60
