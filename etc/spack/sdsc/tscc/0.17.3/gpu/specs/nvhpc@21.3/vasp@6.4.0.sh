#!/usr/bin/env bash

#SBATCH --job-name=vasp@6.4.0
#SBATCH --account=sys200
#SBATCH --partition=hotel-gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH -w gpu1
#SBATCH --time=00:30:00
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
declare -xr COMPILER_MODULE='nvhpc/21.3'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_MODULE}"
module load "${MPI_MODULE}"

# => Error: InstallError: cray-libsci is not installable, you need to specify it as an external package in packages.yaml
#
# /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/var/spack/repos/builtin/packages/cray-libsci/package.py:93, in install:
#         91    def install(self, spec, prefix):
#         92        raise InstallError(
#  >>     93            self.spec.format('{name} is not installable, you need to specify '
#         94                             'it as an external package in packages.yaml'))

# ==> Error: Failed to install vasp6 due to PermissionError: [Errno 1] Operation not permitted: '/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/vasp6-6.4.0-3evo6umbfr5wdmropulmo7ntzkev5hqh'

#             A/lib/libCudaUtils_x86_64.a -L/home/mkandes/cm/shared/apps/spack/0.
#            17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/cuda-11.2.2-
#            blza2psofa3wr2zumqrnh4je2f7ze3mx/lib64 -lnvToolsExt -lcudart -lcuda
#             -lcufft -lcublas
#  >> 714    /usr/bin/ld: cannot find -lcuda
#  >> 715    collect2: error: ld returned 1 exit status
#     716    make[2]: *** [makefile:149: vasp] Error 1
#     717    make[2]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-va
#            sp6-6.4.0-3evo6umbfr5wdmropulmo7ntzkev5hqh/spack-src/build/gpu'
#  >> 718    cp: cannot stat 'vasp': No such file or directory
#     719    make[1]: *** [makefile:146: all] Error 1
#     720    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-va
#            sp6-6.4.0-3evo6umbfr5wdmropulmo7ntzkev5hqh/spack-src/build/gpu'
#     721    make: *** [makefile:17: gpu] Error 2

declare -xr SPACK_PACKAGE='vasp@6.4.0'
declare -xr SPACK_COMPILER="nvhpc@21.3"
declare -xr SPACK_VARIANTS="+acc ~openmp +scalapack ~vaspsol"
declare -xr SPACK_DEPENDENCIES="^intel-mkl@2020.4.304 % ${SPACK_COMPILER}"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types vasp@6.4.0 % nvhpc@21.3 +acc ~openmp +scalapack ~vaspsol "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install -v --jobs 1 --fail-fast --yes-to-all vasp@6.4.0 % nvhpc@21.3 +acc ~openmp +scalapack  ~vaspsol "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 20
