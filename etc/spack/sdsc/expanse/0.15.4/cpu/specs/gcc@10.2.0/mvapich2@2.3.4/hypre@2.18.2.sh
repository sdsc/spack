#!/usr/bin/env bash

#SBATCH --job-name=hypre@2.18.2
#SBATCH --account=use300
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.15.4'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR="${HOME}/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

declare -xr SLURM_JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr SLURM_JOB_MD5SUM="$(md5sum ${SLURM_JOB_SCRIPT})"

declare -xr SCHEDULER_MODULE='slurm/expanse/20.02.3'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

# Failed to build with +superlu-dist ... problem unknown; may be intsize-related
# >> 443    superlu.c:25:4: error: unknown type name 'LUstruct_t'
#     444       25 |    LUstruct_t dslu_data_LU;
#     445          |    ^~~~~~~~~~
#  >> 446    superlu.c:29:4: error: unknown type name 'ScalePermstruct_t'
#     447       29 |    ScalePermstruct_t dslu_ScalePermstruct;
#     448          |    ^~~~~~~~~~~~~~~~~
#  >> 449    superlu.c:30:4: error: unknown type name 'SOLVEstruct_t'
#     450       30 |    SOLVEstruct_t dslu_solve;
#     451          |    ^~~~~~~~~~~~~
#     452    In file included from _hypre_parcsr_ls.h:17,
#     453                     from superlu.c:8:
#     454    superlu.c: In function 'hypre_SLUDistSetup':
#     455    ./../seq_mv/seq_mv.h:77:57: warning: passing argument 8 of 'dCreate
#            _CompRowLoc_Matrix_dist' from incompatible pointer type [-Wincompat
#            ible-pointer-types]
#
#     ...
#
#     578          |                                                  |
#     579          |                                                  int *
#     580    In file included from superlu.c:15:
#     581    /home/mkandes/cm/shared/apps/spack/0.15.4/cpu/opt/spack/linux-cento
#            s8-zen2/gcc-10.2.0/superlu-dist-6.3.0-ucxl6pek4rqu6z3mo56pk3oowqbgz
#            h72/include/superlu_ddefs.h:427:54: note: expected 'dSOLVEstruct_t 
#            *' but argument is of type 'int *'
#     582      427 | extern void dSolveFinalize(superlu_dist_options_t *, dSOLVE
#            struct_t *);
#     583          |                                                      ^~~~~~
#            ~~~~~~~~~~
#  >> 584    make[1]: *** [../config/Makefile.config:42: superlu.o] Error 1
#     585    make[1]: *** Waiting for unfinished jobs....
#     586    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-hy
#            pre-2.18.2-hbi6fnyzv66kmg4zks2l454f4d6z4f45/spack-src/src/parcsr_ls
#            '
#     587    make: *** [Makefile:86: all] Error 1
#
# Set ~superlu-dist for now ...
declare -xr SPACK_PACKAGE='hypre@2.18.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~complex ~debug +int64 ~internal-superlu ~mixedint +mpi ~openmp +shared ~superlu-dist'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^mvapich2@2.3.4/$(spack find --format '{hash:7}' mvapich2@2.3.4 % ${SPACK_COMPILER})"
#^superlu-dist@6.3.0/$(spack find --format '{hash:7}' superlu-dist@6.3.0 % ${SPACK_COMPILER} ^mvapich2@2.3.4)"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
