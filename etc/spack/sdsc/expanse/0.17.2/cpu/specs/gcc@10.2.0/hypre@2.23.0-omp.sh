#!/usr/bin/env bash

#SBATCH --job-name=hypre@2.23.0-omp
#SBATCH --account=use300
#SBATCH --reservation=root_63
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.2'
declare -xr SPACK_INSTANCE_NAME='cpu'
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

declare -xr SPACK_PACKAGE='hypre@2.23.0'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~complex ~cuda ~debug +fortran ~int64 ~internal-superlu ~mixedint ~mpi +openmp +shared ~superlu-dist ~unified-memory'
# Unable to compile with +openmp; possible linking issue to libomp? sort out another time; Spack package existing hypre options are not extensive when compared to configure options; also complex support should probbaly not be an option at this time; complex support very limited
#751    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/hypre_prefix_sum.o: In func
#            tion `hypre_prefix_sum':
#  >> 752    hypre_prefix_sum.c:(.text+0x3a): undefined reference to `omp_in_par
#            allel'
#     753    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/hypre_prefix_sum.o: In func
#            tion `hypre_prefix_sum_pair':
#  >> 754    hypre_prefix_sum.c:(.text+0xe3): undefined reference to `omp_in_par
#            allel'
#     755    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/hypre_prefix_sum.o: In func
#            tion `hypre_prefix_sum_triple':
#  >> 756    hypre_prefix_sum.c:(.text+0x27a): undefined reference to `omp_in_pa
#            rallel'
#     757    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/hypre_prefix_sum.o: In func
#            tion `hypre_prefix_sum_multiple':
#  >> 758    hypre_prefix_sum.c:(.text+0x310): undefined reference to `omp_in_pa
#            rallel'
#     759    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/threading.o: In function `h
#            ypre_NumThreads':
#  >> 760    threading.c:(.text+0x5): undefined reference to `omp_get_max_thread
#            s'
#     761    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/threading.o: In function `h
#            ypre_NumActiveThreads':
#  >> 762    threading.c:(.text+0x13): undefined reference to `omp_get_num_threa
#            ds'
#     763    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/threading.o: In function `h
#            ypre_GetThreadNum':
#  >> 764    threading.c:(.text+0x21): undefined reference to `omp_get_thread_nu
#            m'
#     765    /tmp/mkandes/spack-stage/spack-stage-hypre-2.19.0-lbbskfsddqisbif5d
#            4nhrafc4352avyy/spack-src/src/utilities/threading.o: In function `h
#            ypre_SetNumThreads':
#  >> 766    threading.c:(.text+0x2f): undefined reference to `omp_set_num_threa
#            ds'
#  >> 767    collect2: error: ld returned 1 exit status
#     768    make[1]: *** [Makefile:102: libHYPRE.so] Error 1
#     769    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-hy
#            pre-2.19.0-lbbskfsddqisbif5d4nhrafc4352avyy/spack-src/src/lib'
#     770    make: *** [Makefile:86: all] Error 1
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.18/$(spack find --format '{hash:7}' openblas@0.3.18  % gcc@10.2.0 ~ilp64 threads=none)"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'suite-sparse@5.10.1.sh'

sleep 60
