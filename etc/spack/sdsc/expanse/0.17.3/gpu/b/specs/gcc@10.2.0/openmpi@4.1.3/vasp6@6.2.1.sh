#!/usr/bin/env bash

#SBATCH --job-name=vasp6@6.2.1
#SBATCH --account=use300
#SBATCH --reservation=root_73
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
declare -xr COMPILER_MODULE='gcc/10.2.0'
declare -xr CUDA_MODULE='cuda/11.2.2'
declare -xr MPI_MODULE='openmpi/4.1.3'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_MODULE}"
module load "${CUDA_MODULE}"
module load "${MPI_MODULE}"

# => Error: InstallError: cray-libsci is not installable, you need to specify it as an external package in packages.yaml
#
# /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/var/spack/repos/builtin/packages/cray-libsci/package.py:93, in install:
#         91    def install(self, spec, prefix):
#         92        raise InstallError(
#  >>     93            self.spec.format('{name} is not installable, you need to specify '
#         94                             'it as an external package in packages.yaml'))

# ==> Error: Failed to install vasp6 due to PermissionError: [Errno 1] Operation not permitted: '/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/vasp6-6.2.1-3evo6umbfr5wdmropulmo7ntzkev5hqh'

#             A/lib/libCudaUtils_x86_64.a -L/home/mkandes/cm/shared/apps/spack/0.
#            17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/cuda-11.2.2-
#            blza2psofa3wr2zumqrnh4je2f7ze3mx/lib64 -lnvToolsExt -lcudart -lcuda
#             -lcufft -lcublas
#  >> 714    /usr/bin/ld: cannot find -lcuda
#  >> 715    collect2: error: ld returned 1 exit status
#     716    make[2]: *** [makefile:149: vasp] Error 1
#     717    make[2]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-va
#            sp6-6.2.1-3evo6umbfr5wdmropulmo7ntzkev5hqh/spack-src/build/gpu'
#  >> 718    cp: cannot stat 'vasp': No such file or directory
#     719    make[1]: *** [makefile:146: all] Error 1
#     720    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-va
#            sp6-6.2.1-3evo6umbfr5wdmropulmo7ntzkev5hqh/spack-src/build/gpu'
#     721    make: *** [makefile:17: gpu] Error 2

declare -xr SPACK_PACKAGE='vasp6@6.2.1'
declare -xr SPACK_COMPILER="gcc@10.2.0"
declare -xr SPACK_VARIANTS="ldflags='-L/cm/local/apps/cuda/libs/current/lib64' +cuda ~openmp +scalapack +shmem ~vaspsol"
declare -xr SPACK_DEPENDENCIES="^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^openmpi@4.1.3/$(spack find --format '{hash:7}' openmpi@4.1.3 % ${SPACK_COMPILER}) ^netlib-scalapack@2.1.0/$(spack find --format '{hash:7}' netlib-scalapack@2.1.0 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types vasp6@6.2.1 % gcc@10.2.0 +cuda ~openmp +scalapack +shmem ~vaspsol "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

export LDFLAGS='-L/cm/local/apps/cuda/libs/current/lib64'
time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all vasp6@6.2.1 % gcc@10.2.0 +cuda ~openmp +scalapack +shmem ~vaspsol "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 30
