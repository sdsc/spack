#!/usr/bin/env bash

#SBATCH --job-name=vasp6@6.2.1
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=01:00:00
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
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module list

# >> 1216    ld.lld: error: unable to find library -lfftw3_omp
#  >> 1217    clang-13: error: linker command failed with exit code 1 (use -v to
#              see invocation)
#     1218    make[2]: *** [makefile:149: vasp] Error 1
#     1219    make[2]: Leaving directory '/scratch/spack_cpu/job_21117029/spack-
#             stage/spack-stage/spack-stage-vasp6-6.2.1-vu7hji2vkfvdaommo64n4y4z
#             hajhvydt/spack-src/build/std'
#  >> 1220    cp: cannot stat 'vasp': No such file or directory
#     1221    make[1]: *** [makefile:146: all] Error 1
#     1222    make[1]: Leaving directory '/scratch/spack_cpu/job_21117029/spack-
#             stage/spack-stage/spack-stage-vasp6-6.2.1-vu7hji2vkfvdaommo64n4y4z
#             hajhvydt/spack-src/build/std'
#     1223    make: *** [makefile:17: std] Error 2

# >> 1057    ld.lld: error: undefined symbol: m_sum_s_
#     1058    >>> referenced by solvation.f90:1687
#     1059    >>>               solvation.o:(pot_k_vcorrection_)
#     1060    >>> referenced by solvation.f90:1697
#     1061    >>>               solvation.o:(pot_k_vcorrection_)
#     1062    >>> did you mean: m_sumb_s_
#     1063    >>> defined in: mpi.o
#  >> 1064    clang-13: error: linker command failed with exit code 1 (use -v to
#              see invocation)
#     1065    make[2]: *** [makefile:149: vasp] Error 1
#     1066    make[2]: Leaving directory '/scratch/spack_cpu/job_21126571/spack-
#             stage/spack-stage/spack-stage-vasp6-6.2.1-c4lbyn5edkydi42hwwnot3wo
#             v25v7z3e/spack-src/build/std'
#  >> 1067    cp: cannot stat 'vasp': No such file or directory
#     1068    make[1]: *** [makefile:146: all] Error 1
#     1069    make[1]: Leaving directory '/scratch/spack_cpu/job_21126571/spack-
#             stage/spack-stage/spack-stage-vasp6-6.2.1-c4lbyn5edkydi42hwwnot3wo
#             v25v7z3e/spack-src/build/std'
#     1070    make: *** [makefile:17: std] Error 2

declare -xr SPACK_PACKAGE='vasp6@6.2.1'
declare -xr SPACK_COMPILER='aocc@3.2.0'
declare -xr SPACK_VARIANTS='~cuda ~openmp +scalapack +shmem ~vaspsol'
declare -xr SPACK_DEPENDENCIES="^amdfftw@3.1/$(spack find --format '{hash:7}' amdfftw@3.1 % ${SPACK_COMPILER} ~mpi ~openmp) ^amdscalapack@3.1/$(spack find --format '{hash:7}' amdscalapack@3.1 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 30
