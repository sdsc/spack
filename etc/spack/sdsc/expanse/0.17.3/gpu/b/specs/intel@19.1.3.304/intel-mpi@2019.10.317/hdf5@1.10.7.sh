#!/usr/bin/env bash

#SBATCH --job-name=hdf5@1.10.7
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
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

declare -xr LOCAL_SCRATCH_DIR="/scratch/${USER}/job_${SLURM_JOB_ID}"
declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='gpu'
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

# 3 errors found in build log:
#     4340    /scratch/mkandes/job_1413/spack-stage/spack-stage-hdf5-1.10.7-ceea
#             hiv64am7vxjv6s5tfjty2cyx6gxp/spack-build-ceeahiv/fortran/static/H5
#             _gen.F90(5956): warning #7025: This directive is not standard F200
#             3.
#     4341    !DEC$endif
#     4342    -----^
#     4343    /scratch/mkandes/job_1413/spack-stage/spack-stage-hdf5-1.10.7-ceea
#             hiv64am7vxjv6s5tfjty2cyx6gxp/spack-build-ceeahiv/fortran/static/H5
#             _gen.F90(5967): warning #7025: This directive is not standard F200
#             3.
#     4344    !DEC$if defined(BUILD_HDF5_DLL)
#     4345    -----^
#  >> 4346    /scratch/mkandes/job_1413/spack-stage/spack-stage-hdf5-1.10.7-ceea
#             hiv64am7vxjv6s5tfjty2cyx6gxp/spack-build-ceeahiv/fortran/static/H5
#             _gen.F90(5967): error #5174: Unterminated conditional compilation 
#             directive
#     4347    !DEC$if defined(BUILD_HDF5_DLL)
#     4348    -------------------------------^
#     4349    compilation aborted for /scratch/mkandes/job_1413/spack-stage/spac
#             k-stage-hdf5-1.10.7-ceeahiv64am7vxjv6s5tfjty2cyx6gxp/spack-build-c
#             eeahiv/fortran/static/H5_gen.F90 (code 1)
#  >> 4350    make[2]: *** [fortran/src/CMakeFiles/hdf5_fortran-static.dir/build
#             .make:324: fortran/src/CMakeFiles/hdf5_fortran-static.dir/__/stati
#             c/H5_gen.F90.o] Error 1
#     4351    make[2]: Leaving directory '/scratch/mkandes/job_1413/spack-stage/
#             spack-stage-hdf5-1.10.7-ceeahiv64am7vxjv6s5tfjty2cyx6gxp/spack-bui
#             ld-ceeahiv'
#  >> 4352    make[1]: *** [CMakeFiles/Makefile2:2055: fortran/src/CMakeFiles/hd
#             f5_fortran-static.dir/all] Error 2

declare -xr INTEL_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='hdf5@1.10.7'
declare -xr SPACK_COMPILER='intel@19.1.3.304'
declare -xr SPACK_VARIANTS='+cxx +fortran +hl ~ipo +java +mpi +shared ~szip ~threadsafe +tools'
declare -xr SPACK_DEPENDENCIES="^intel-mpi@2019.10.317/$(spack find --format '{hash:7}' intel-mpi@2019.10.317 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'parmetis@4.0.3.sh'

sleep 30
