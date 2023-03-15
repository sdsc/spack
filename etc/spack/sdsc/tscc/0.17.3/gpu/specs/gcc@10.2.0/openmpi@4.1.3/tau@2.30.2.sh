#!/usr/bin/env bash

#SBATCH --job-name=tau@2.30.2
#SBATCH --account=sdsc
#SBATCH --partition=hotel
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

declare -xr SPACK_VERSION='0.17.3'
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


# build problem when +python related to boost?
#
# >> 700    ld: cannot find -lboost_python
#  >> 701    collect2: error: ld returned 1 exit status
#     702    make[1]: *** [Makefile:440: pytau_cuda.so] Error 1
#     703    make[1]: *** Waiting for unfinished jobs....
#     704    cd /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-ro
#            cky8-cascadelake/gcc-10.2.0/tau-2.30.2-c64xr2mrq6ybwwnzunffebi3z7dg
#            ytnk/x86_64/lib && /bin/ln -sf shared-papi-mpi-pthread-python-cupti
#            -pdt bindings-papi-mpi-pthread-python-cupti-pdt
#     705    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-ta
#            u-2.30.2-c64xr2mrq6ybwwnzunffebi3z7dgytnk/spack-src/src/Profile'
#     706    make: *** [Makefile:192: install] Error 2

declare -xr SPACK_PACKAGE='tau@2.30.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~adios2 +binutils ~comm ~craycnl +cuda +elf +fortran ~gasnet +io ~level_zero +libdwarf +libunwind ~likwid +mpi ~ompt ~opari ~opencl ~openmp +otf2 +papi +pdt ~phase ~ppc64le ~profileparam +pthreads ~python ~rocm ~rocprofiler ~roctracer ~scorep ~shmem +sqlite ~x86_64'
declare -xr SPACK_DEPENDENCIES="^openmpi@4.1.3/$(spack find --format '{hash:7}' openmpi@4.1.3 % ${SPACK_COMPILER}) ^papi@6.0.0.1/$(spack find --format '{hash:7}' papi@6.0.0.1 % ${SPACK_COMPILER})" #^python@3.8.12/$(spack find --format '{hash:7}' python@3.8.12 % ${SPACK_COMPILER})"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'scotch@6.1.1.sh'

sleep 60
