#!/usr/bin/env bash

#SBATCH --job-name=quantum-espresso@7.0
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=48:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr LOCAL_SCRATCH_DIR="/scratch/${USER}/job_${SLURM_JOB_ID}"
declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_VERSION='b'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}/${SPACK_INSTANCE_VERSION}"

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

# QE v6.7 does not concretize with a +scalapack dependency using 
# standard package available in spack v0.17.2? Fixed when updating to
# latest spack develop branch on 2022/03/11. Placed in sdsc spack 
# package repo. Then upgraded to QE v7.0 instead.

# unsatisfiable, conflicts are:
#  condition(34)
#  hash("amdlibflame","sne2ugsk2pbc3uwllbipkyeajd5m2vzq")
#  imposed_constraint("sne2ugsk2pbc3uwllbipkyeajd5m2vzq","hash","amdblis","hx3awsc47q3rvseitz2exudsvxnvt6qa")
#  node("amdblis")
#  variant_condition(34,"amdblis","threads")
#  variant_set("amdblis","threads","openmp")

# unsatisfiable, conflicts are:
#  condition(4599)
#  condition(4600)
#  condition(4606)
#  condition(4610)
#  condition(4659)
#  condition(803)
#  dependency_condition(4659,"quantum-espresso","elpa")
#  dependency_condition(803,"elpa","python")
#  dependency_type(4659,"build")
#  dependency_type(803,"build")
#  hash("amdlibflame","z4pyd3f3n6ddmbzupc3lo6pd3g3a6awa")
#  imposed_constraint("kiytcz3y2paxpfhkyelowqdhznp7w2rf","version","python","3.8.12")
#  imposed_constraint("z4pyd3f3n6ddmbzupc3lo6pd3g3a6awa","hash","python","kiytcz3y2paxpfhkyelowqdhznp7w2rf")
#  imposed_constraint(803,"version_satisfies","python",":2")
#  no version satisfies the given constraints
#  root("quantum-espresso")
#  variant_condition(4599,"quantum-espresso","cmake")
#  variant_condition(4600,"quantum-espresso","elpa")
#  variant_condition(4606,"quantum-espresso","mpi")
#  variant_condition(4610,"quantum-espresso","scalapack")
#  variant_set("quantum-espresso","cmake","True")
#  variant_set("quantum-espresso","elpa","True")
#  variant_set("quantum-espresso","mpi","True")
#  variant_set("quantum-espresso","scalapack","True")
#  version_satisfies("elpa","2019.11.001")
#  version_satisfies("elpa",":2020.05.001","2019.11.001")

# unsatisfiable, conflicts are:
#  A conflict was triggered
#  All dependencies must be reachable from root
#  condition(46)
#  condition(4607)
#  condition(4617)
#  condition(4618)
#  conflict("quantum-espresso",4617,4618)
#  node("amdfftw")
#  variant_condition(46,"amdfftw","openmp")
#  variant_condition(4607,"quantum-espresso","openmp")
#  variant_set("amdfftw","openmp","False")
#  variant_set("quantum-espresso","openmp","True")

# 1 error found in build log:
#     46    -- Looking for Fortran sgemm
#     47    -- Looking for Fortran sgemm - not found
#     48    -- Could NOT find BLAS (missing: BLAS_LIBRARIES)
#     49    -- Could NOT find LAPACK (missing: LAPACK_LIBRARIES)
#     50        Reason given by package: LAPACK could not be found because depen
#           dency BLAS could not be found.
#     51    
#  >> 52    CMake Error at CMakeLists.txt:418 (message):
#     53      Failed to find a complete set of external BLAS/LAPACK library by
#     54      FindLAPACK.  Variables controlling FindLAPACK can be found at CMak
#           e online
#     55      documentation.  Alternatively, '-DQE_LAPACK_INTERNAL=ON' may be us
#           ed to
#     56      enable reference LAPACK at a performance loss compared to optimize
#           d
#     57      libraries.
#     58    

# unsatisfiable, conflicts are:
#  A conflict was triggered
#  All dependencies must be reachable from root
#  condition(4599)
#  condition(4613)
#  condition(4614)
#  conflict("quantum-espresso",4613,4614)
#  no version satisfies the given constraints
#  node("amdscalapack")
#  variant_condition(4599,"quantum-espresso","cmake")
#  variant_set("quantum-espresso","cmake","True")
#  version_satisfies("quantum-espresso","6.7")
#  version_satisfies("quantum-espresso",":6.7","6.7")

# unsatisfiable, conflicts are:
#  A conflict was triggered
#  All dependencies must be reachable from root
#  Unsatisfied conditional variants cannot be set
#  condition(4613)
#  condition(4614)
#  condition_requirement(4605,"variant_value","quantum-espresso","cmake","True")
#  conflict("quantum-espresso",4613,4614)
#  no version satisfies the given constraints
#  node("amdscalapack")
#  variant_set("quantum-espresso","libxc","False")
#  version_satisfies("quantum-espresso","6.7")
#  version_satisfies("quantum-espresso",":6.7","6.7")

declare -xr SPACK_PACKAGE='quantum-espresso@7.0'
declare -xr SPACK_COMPILER='aocc@3.2.0'
declare -xr SPACK_VARIANTS='~cmake ~elpa ~environ hdf5=parallel +epw ~ipo ~libxc +mpi +openmp +patch ~qmcpack +scalapack'
declare -xr SPACK_DEPENDENCIES="^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^amdlibflame@3.1/$(spack find --format '{hash:7}' amdlibflame@3.1 % ${SPACK_COMPILER} ~ilp64 threads=none ^amdblis@3.1 ~ilp64 threads=openmp) ^amdfftw@3.1/$(spack find --format '{hash:7}' amdfftw@3.1 % ${SPACK_COMPILER} ~mpi +openmp) ^amdscalapack@3.1/$(spack find --format '{hash:7}' amdscalapack@3.1 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack --show-cores=minimized spec --long --namespaces --types quantum-espresso@7.0 % aocc@3.2.0 ~cmake ~elpa ~environ hdf5=parallel +epw ~ipo +libxc +mpi +openmp +patch ~qmcpack +scalapack "^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^amdlibflame@3.1/$(spack find --format '{hash:7}' amdlibflame@3.1 % ${SPACK_COMPILER} ~ilp64 threads=none ^amdblis@3.1 ~ilp64 threads=openmp) ^amdfftw@3.1/$(spack find --format '{hash:7}' amdfftw@3.1 % ${SPACK_COMPILER} ~mpi +openmp) ^amdscalapack@3.1/$(spack find --format '{hash:7}' amdscalapack@3.1 % ${SPACK_COMPILER} ^amdblis@3.1 ~ilp64 threads=openmp)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all quantum-espresso@7.0 % aocc@3.2.0 ~cmake ~elpa ~environ hdf5=parallel +epw ~ipo +libxc +mpi +openmp +patch ~qmcpack +scalapack "^hdf5@1.10.7/$(spack find --format '{hash:7}' hdf5@1.10.7 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^amdlibflame@3.1/$(spack find --format '{hash:7}' amdlibflame@3.1 % ${SPACK_COMPILER} ~ilp64 threads=none ^amdblis@3.1 ~ilp64 threads=openmp) ^amdfftw@3.1/$(spack find --format '{hash:7}' amdfftw@3.1 % ${SPACK_COMPILER} ~mpi +openmp) ^amdscalapack@3.1/$(spack find --format '{hash:7}' amdscalapack@3.1 % ${SPACK_COMPILER} ^amdblis@3.1 ~ilp64 threads=openmp)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

##spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'quantum-espresso@6.4.1.sh'
#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'paraview@5.9.1.sh'

sleep 30
