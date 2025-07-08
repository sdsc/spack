#!/usr/bin/env bash

#SBATCH --job-name=arrayfire@3.9.0
#SBATCH --account=use300
#SBATCH --reservation=root_73
#SBATCH --clusters=expanse
#SBATCH --partition=ind-gpu-shared
#SBATCH --qos=gpu-unlim
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=92G
#SBATCH --gpus=1
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xir UNIX_TIME="$(date +'%s')"
declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"

declare -xr JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr JOB_SCRIPT_MD5="$(md5sum ${JOB_SCRIPT} | awk '{print $1}')"
declare -xr JOB_SCRIPT_SHA256="$(sha256sum ${JOB_SCRIPT} | awk '{print $1}')"
declare -xr JOB_SCRIPT_NUMBER_OF_LINES="$(wc -l ${JOB_SCRIPT} | awk '{print $1}')"

declare -xr SCHEDULER_NAME='slurm'
declare -xr SCHEDULER_MAJOR='23'
declare -xr SCHEDULER_MINOR='02'
declare -xr SCHEDULER_REVISION='7'
declare -xr SCHEDULER_VERSION="${SCHEDULER_MAJOR}.${SCHEDULER_MINOR}.${SCHEDULER_REVISION}"
declare -xr SCHEDULER_MODULE="${SCHEDULER_NAME}/${SLURM_CLUSTER_NAME}/${SCHEDULER_VERSION}"

declare -xr COMPILER_NAME='gcc'
declare -xr COMPILER_MAJOR='11'
declare -xr COMPILER_MINOR='5'
declare -xr COMPILER_REVISION='0'
declare -xr COMPILER_VERSION="${COMPILER_MAJOR}.${COMPILER_MINOR}.${COMPILER_REVISION}"
declare -xr COMPILER_MODULE="${COMPILER_NAME}/${COMPILER_VERSION}"

declare -xr CUDA_NAME='cuda'
declare -xr CUDA_MAJOR='11'
declare -xr CUDA_MINOR='8'
declare -xr CUDA_REVISION='0'
declare -xr CUDA_VERSION="${CUDA_MAJOR}.${CUDA_MINOR}.${CUDA_REVISION}"
declare -xr CUDA_MODULE="${CUDA_NAME}/${CUDA_VERSION}"

declare -xr SPACK_MAJOR='0'
declare -xr SPACK_MINOR='21'
declare -xr SPACK_REVISION='2'
declare -xr SPACK_VERSION="${SPACK_MAJOR}.${SPACK_MINOR}.${SPACK_REVISION}"
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_VERSION='dev'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}/${SPACK_INSTANCE_VERSION}"

declare -xr TMPDIR="${SLURM_TMPDIR}/spack-stage"
declare -xr TMP="${TMPDIR}"

echo "${UNIX_TIME} ${LOCAL_TIME} ${SLURM_JOB_ID} ${JOB_SCRIPT_MD5} ${JOB_SCRIPT_SHA256} ${JOB_SCRIPT_NUMBER_OF_LINES} ${JOB_SCRIPT}"
cat  "${JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_MODULE}"
module load "${CUDA_MODULE}"
module list

# 4 errors found in build log:
#     138    -- Found BLAS: /home/mkandes/software/spack/repos/sdsc/gpu/opt/spac
#            k/linux-rocky8-cascadelake/gcc-13.3.0/openblas-0.3.28-mozdastvpdzuk
#            mxujpvb3fvqitexksvx/lib/libopenblas.so
#     139    -- Looking for cheev_
#     140    -- Looking for cheev_ - found
#     141    -- Found LAPACK: /home/mkandes/software/spack/repos/sdsc/gpu/opt/sp
#            ack/linux-rocky8-cascadelake/gcc-13.3.0/openblas-0.3.28-mozdastvpdz
#            ukmxujpvb3fvqitexksvx/lib/libopenblas.so;-lpthread;-lm;-ldl
#     142    -- Build spdlog: 1.9.2
#     143    -- Build type: Release
#  >> 144    CMake Error at CMakeLists.txt:313 (add_subdirectory):
#     145      add_subdirectory not given a binary directory but the given sourc
#            e
#     146      directory
#     147      "/scratch/mkandes/job_36282250/spack-stage/spack-stage/spack-stag
#            e-arrayfire-3.9.0-plo6ogf6tivlpl772ryfzjepqxwjvonv/spack-build-plo6
#            ogf/extern/span-lite-src"
#     148      is not a subdirectory of
#     149      "/scratch/mkandes/job_36282250/spack-stage/spack-stage/spack-stag
#            e-arrayfire-3.9.0-plo6ogf6tivlpl772ryfzjepqxwjvonv/spack-src".
#     150      When specifying an out-of-tree source a binary directory must be 
#            explicitly
#     151      specified.
#     152    
#     153    
#  >> 154    CMake Error at CMakeLists.txt:314 (get_property):
#     155      get_property could not find TARGET span-lite.  Perhaps it has not
#             yet been
#     156      created.
#     157    
#     158    
#  >> 159    CMake Error at CMakeLists.txt:317 (set_target_properties):
#     160      set_target_properties Can not find target to add properties to: s
#            pan-lite
#     161    
#     162    
#  >> 163    CMake Error at CMakeLists.txt:319 (set_target_properties):
#     164      set_target_properties Can not find target to add properties to: s
#            pan-lite
#     165    
#     166    
#     167    -- CUDA driver library missing. Looking for libcuda stub.
#     168    -- CUDA driver stub FOUND: /home/mkandes/software/spack/repos/sdsc/
#            gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/cuda-12.6.3-guub3
#            z6c6k7zgb3qv3vdngxr6zu5mhzy/lib64/stubs/libcuda.so
#     169    -- Performing Test has_ignored_attributes_flag

declare -xr SPACK_PACKAGE='arrayfire@3.9.0'
declare -xr SPACK_COMPILER='gcc@11.5.0'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=70,80 ~forge ~ipo ~opencl'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.28/$(spack find --format '{hash:7}' openblas@0.3.28 % ${SPACK_COMPILER} ~ilp64 threads=none) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^boost@1.86.0/$(spack find --format '{hash:7}' boost@1.86.0 % ${SPACK_COMPILER} ~mpi) ^cuda@11.8.0/$(spack find --format '{hash:7}' cuda@11.8.0 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types --reuse "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

mkdir -p "${TMPDIR}"

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all --reuse "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi
