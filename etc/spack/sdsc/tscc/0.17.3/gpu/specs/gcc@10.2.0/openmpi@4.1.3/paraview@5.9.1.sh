#!/usr/bin/env bash

#SBATCH --job-name=paraview@5.9.1
#SBATCH --account=sys200
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus=4
#SBATCH --time=48:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='tscc'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='gpu'
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

# 1 error found in build log:
#     182    --  conduit::float64 native type: double
#     183    -- Detecting Fortran/C Interface
#     184    -- Detecting Fortran/C Interface - Found GLOBAL and MODULE mangling
#     185    -- Found Python3: /home/mkandes/cm/shared/apps/spack/0.17.3/cpu/opt
#            /spack/linux-rocky8-zen2/gcc-10.2.0/python-3.8.12-dtdsuje4z5v7rqevi
#            nukk4n37p3lxjcn/include/python3.8 (found version "3.8.12") found co
#            mponents: Development Development.Module Development.Embed
#     186    -- Enabled modules: VTK(51), ParaView(20 + 3)
#     187    -- Configuring done
#  >> 188    CMake Error: The inter-target dependency graph contains the followi
#            ng strongly connected component (cycle):
#     189      "Parallel" of type SHARED_LIBRARY
#     190        depends on "ParallelMPI-objects" (weak)
#     191        depends on "ParallelCore-objects" (weak)
#     192        depends on "IO" (weak)
#     193        depends on "IOParallelXML-objects" (weak)
#     194        depends on "FiltersExtraction-objects" (weak)
#
#See build log for details:
#  /tmp/mkandes/spack-stage/spack-stage-paraview-5.9.1-nvcndznztjdzufmpkor2bqb6ffzftim7/spack-build-out.txt

# CMake Error: The inter-target dependency graph contains the following strongly connected component (cycle):
#  "Parallel" of type SHARED_LIBRARY
#    depends on "ParallelMPI-objects" (weak)
#    depends on "ParallelCore-objects" (weak)
#    depends on "IO" (weak)
#    depends on "IOParallelXML-objects" (weak)
#    depends on "FiltersExtraction-objects" (weak)
#    depends on "ParallelDIY-objects" (weak)
#  "IO" of type SHARED_LIBRARY
#    depends on "IOADIOS2-objects" (weak)
#    depends on "ParallelCore-objects" (weak)
#    depends on "Parallel" (weak)
#    depends on "ParallelMPI-objects" (weak)
#  "ParallelCore-objects" of type OBJECT_LIBRARY
#    depends on "IO" (weak)
#  "ParallelMPI-objects" of type OBJECT_LIBRARY
#    depends on "ParallelCore-objects" (weak)
#    depends on "IO" (weak)
#  "IOParallelXML-objects" of type OBJECT_LIBRARY
#    depends on "IO" (weak)
#    depends on "ParallelCore-objects" (weak)
#  "IOADIOS2-objects" of type OBJECT_LIBRARY
#    depends on "ParallelCore-objects" (weak)
#    depends on "IO" (weak)
#    depends on "Parallel" (weak)
#    depends on "ParallelMPI-objects" (weak)
#  "ParallelDIY-objects" of type OBJECT_LIBRARY
#    depends on "ParallelCore-objects" (weak)
#    depends on "IO" (weak)
#    depends on "ParallelMPI-objects" (weak)
#  "FiltersExtraction-objects" of type OBJECT_LIBRARY
#    depends on "ParallelDIY-objects" (weak)
#    depends on "ParallelCore-objects" (weak)
#    depends on "IO" (weak)
#    depends on "ParallelMPI-objects" (weak)
#At least one of these targets is not a STATIC_LIBRARY.  Cyclic dependencies are allowed only among static libraries.
#CMake Generate step failed.  Build files cannot be regenerated correctly.

# adios2 needs to be ~shared?

# A conflict was triggered
#  condition(3642)
#  condition(3655)
#  condition(3801)
#  condition(3802)
#  conflict("paraview",3801,3802)
#  root("paraview")
#  variant_condition(3642,"paraview","cuda")
#  variant_condition(3655,"paraview","shared")
#  variant_set("paraview","cuda","True")
#  variant_set("paraview","shared","True")

# 1 error found in build log:
#     182    --  conduit::float32 native type: float
#     183    --  conduit::float64 native type: double
#     184    -- Detecting Fortran/C Interface
#     185    -- Detecting Fortran/C Interface - Found GLOBAL and MODULE mangling
#     186    -- Enabled modules: VTK(50), ParaView(20 + 3)
#     187    -- Configuring done
#  >> 188    CMake Error: The inter-target dependency graph contains the followi
#            ng strongly connected component (cycle):
#     189      "vtkPVInSituPython" of type STATIC_LIBRARY
#     190        depends on "InSitu-objects" (weak)
#     191        depends on "PythonCatalyst-objects" (weak)
#     192        depends on "PythonInitializer" (weak)
#     193        depends on "vtkPVCatalystPython" (weak)
#     194        depends on "ClientKit" (weak)

# A conflict was triggered
#  condition(3650)
#  condition(3803)
#  condition(3804)
#  conflict("paraview",3803,3804)
#  no version satisfies the given constraints
#  root("paraview")
#  variant_condition(3650,"paraview","opengl2")
#  variant_set("paraview","opengl2","False")
#  version_satisfies("paraview","5.5:","5.9.1")
#  version_satisfies("paraview","5.9.1")

declare -xr SPACK_PACKAGE='paraview@5.9.1'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~adios2 ~advanced_debug +cuda cuda_arch=60,75,80,86 ~development_files +examples +hdf5 ~ipo ~kits +mpi +opengl2 ~osmesa ~python +python3 ~qt ~shared'
declare -xr SPACK_DEPENDENCIES="^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^py-matplotlib@3.4.3/$(spack find --format '{hash:7}' py-matplotlib@3.4.3 % ${SPACK_COMPILER}) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types paraview@5.9.1 % gcc@10.2.0 ~adios2 ~advanced_debug +cuda cuda_arch=60,75,80,86 ~development_files +examples +hdf5 ~ipo ~kits +mpi +opengl2 ~osmesa ~python +python3 ~qt ~shared "^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^py-matplotlib@3.4.3/$(spack find --format '{hash:7}' py-matplotlib@3.4.3 % ${SPACK_COMPILER}) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all paraview@5.9.1 % gcc@10.2.0 ~adios2 ~advanced_debug +cuda cuda_arch=60,75,80,86 ~development_files +examples +hdf5 ~ipo ~kits +mpi +opengl2 ~osmesa ~python +python3 ~qt ~shared "^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^py-matplotlib@3.4.3/$(spack find --format '{hash:7}' py-matplotlib@3.4.3 % ${SPACK_COMPILER}) ^netcdf-c@4.8.1/$(spack find --format '{hash:7}' netcdf-c@4.8.1 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'visit@3.1.1.sh'
#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'openfoam@2106.sh'

sleep 20
