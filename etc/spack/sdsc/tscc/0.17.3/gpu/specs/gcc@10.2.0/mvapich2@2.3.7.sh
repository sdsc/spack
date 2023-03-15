#!/usr/bin/env bash

#SBATCH --job-name=mvapich2@2.3.7
#SBATCH --account=sdsc
#SBATCH --partition=hotel
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=93G
#SBATCH --gpus=1
#SBATCH --time=01:00:00
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
declare -xr COMPILER_MODULE='gcc/10.2.0'
declare -xr CUDA_MODULE='cuda/11.3.1'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_MODULE}"
module load "${CUDA_MODULE}"
module list

# Same problem as OMB? Need to allow cuda toolkit libraries and system/driver libraries to be in different locations
#
# ==> mvapich2: Executing phase: 'autoreconf'
# ==> mvapich2: Executing phase: 'configure'
# ==> Error: ProcessError: Command exited with status 1:
#    '/tmp/mkandes/spack-stage/spack-stage-mvapich2-2.3.7-pb6kofezb524r6bt3lang2riohvroyve/spack-src/configure' '--prefix=/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/mvapich2-2.3.7-pb6kofezb524r6bt3lang2riohvroyve' '--enable-shared' '--enable-romio' '--disable-silent-rules' '--disable-new-dtags' '--enable-fortran=all' '--enable-threads=multiple' '--with-ch3-rank-bits=32' '--enable-wrapper-rpath=yes' '--disable-alloca' '--enable-fast=all' '--enable-cuda' '--with-cuda=/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/cuda-11.3.1-gonjgx5gtwrgpnixvmchcaozt6bv2ykl' '--enable-registration-cache' '--with-pmi=pmi2' '--with-pm=slurm' '--with-slurm=/cm/shared/apps/slurm/21.08.8' '--with-device=ch3:mrail' '--with-rdma=gen2' '--disable-mcast' '--with-file-system=lustre'
#
# 2 errors found in build log:
#     531    checking for inline... inline
#     532    checking for getpagesize... yes
#     533    checking for gettimeofday... yes
#     534    checking for memset... yes
#     535    checking for sqrt... yes
#     536    checking for library containing cuPointerGetAttribute... no
#  >> 537    configure: error: cannot link with -lcuda
#  >> 538    configure: error: OMB configure failed

declare -xr SPACK_PACKAGE='mvapich2@2.3.7'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~alloca ch3_rank_bits=32 +cuda ~debug file_systems=lustre process_managers=slurm +regcache threads=multiple +wrapperrpath'
declare -xr SPACK_DEPENDENCIES="^slurm@21.08.8 ^rdma-core@28.0 ^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types mvapich2@2.3.7 % gcc@10.2.0 ~alloca ch3_rank_bits=32 +cuda ~debug file_systems=lustre process_managers=slurm +regcache threads=multiple +wrapperrpath "^slurm@21.08.8 ^rdma-core@28.0 ^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"

if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all mvapich2@2.3.7 % gcc@10.2.0 ~alloca ch3_rank_bits=32 +cuda ~debug file_systems=lustre process_managers=slurm +regcache threads=multiple +wrapperrpath "^slurm@21.08.8 ^rdma-core@28.0 ^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y
