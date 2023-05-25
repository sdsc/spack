#!/usr/bin/env bash

DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load $SPACK_INSTANCE_NAME
module load "${COMPILER_MODULE}"
module load "${MPI_MODULE}"
module load "${CUDA_MODULE}"
module load "${CMAKE_MODULE}"
module list

# 49387    [ 27%] Building CXX object AmberTools/src/cpptraj/src/CMakeFiles/
#              cpptraj_common_obj.dir/Action_Box.cpp.o
#  >> 49388    /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-roc
#              ky8-cascadelake/gcc-10.2.0/cuda-11.2.2-blza2psofa3wr2zumqrnh4je2f
#              7ze3mx/include/thrust/detail/allocator/allocator_traits.h(245): e
#              rror: class "thrust::detail::device_delete_allocator" has no memb
#              er "value_type"
#     49389              detected during:
#     49390                instantiation of class "thrust::detail::allocator_tra
#              its<Alloc> [with Alloc=thrust::detail::device_delete_allocator]"
#     49391    (402): here
#     49392                instantiation of class "thrust::detail::allocator_sys
#              tem<Alloc> [with Alloc=thrust::detail::device_delete_allocator]"
#     49393    /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-roc
#              ky8-cascadelake/gcc-10.2.0/cuda-11.2.2-blza2psofa3wr2zumqrnh4je2f
#              7ze3mx/include/thrust/detail/allocator/destroy_range.inl(137): he
#              re
#
# Fix? Use cuda/10.2.89?
#
# Currently Amber supports CUDA versions from 7.5 to 11.x inclusive (tested only up to 11.2). However, older
# versions are less well tested and more likely to cause issues, and you may also run into trouble with the CUDA
# SDK being incompatible with newer compilers on your machine.

declare -xr SPACK_PACKAGE='amber@22'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=60 +mpi +openmp +update'
declare -xr SPACK_DEPENDENCIES="^intel-mpi@2019.10.317 ^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +fortran  +hl +mpi ~szip ^intel-mpi@2019.10.317) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +parallel-netcdf +mpi ^intel-mpi@2019.10.317) ^netcdf-fortran@4.5.3/$(spack find --format '{hash:7}' netcdf-fortran@4.5.3 % ${SPACK_COMPILER} ^intel-mpi@2019.10.317) ^cuda@10.2.89/$(spack find --format '{hash:7}' cuda@10.2.89 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types amber@22 % gcc@10.2.0 +cuda cuda_arch=60 +mpi +openmp +update "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install -v --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all amber@22 % gcc@10.2.0 +cuda cuda_arch=60 +mpi +openmp +update "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'plumed@2.6.3.sh'

sleep 20
