#!/usr/bin/env bash

#SBATCH --job-name=nccl@2.7.8-1
#SBATCH --account=use300
#SBATCH --partition=gpu-debug
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

declare -xr SPACK_VERSION='0.15.4'
declare -xr SPACK_INSTANCE_NAME='gpu'
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


#==> Installing nccl
#==> No binary for nccl found: installing from source
#==> Warning: Missing a source id for rdma-core@47
#==> Using cached archive: /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/var/spack/cache/_source-cache/archive/fa/fa2bec307270f30fcf6280a85f24ea8801e0ce3b3027937c7325
#260a890b07e0.tar.gz
#==> nccl: Executing phase: 'edit'
#==> nccl: Executing phase: 'build'
#==> Error: ProcessError: Command exited with status 2:
#    'make' '-j10' 'CUDA_HOME=/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-cascadelake/intel-19.1.2.254/cuda-10.2.89-wulkkucah66aloi4zdf4hutj
#7iuwwx2v'
#
#6 errors found in build log:
#     44    graph/search.cc(527): warning #823: reference is to variable "g" (de
#           clared at line 511) -- under old for-init scoping rules it would hav
#           e been variable "g" (declared at line 520)
#     45            intra[g++] = rank;
#     46                  ^
#     47    
#     48    In file included from /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/
#           opt/spack/linux-centos8-cascadelake/intel-19.1.2.254/cuda-10.2.89-wu
#           lkkucah66aloi4zdf4hutj7iuwwx2v/bin/../targets/x86_64-linux/include/c
#           uda_runtime.h(83),
#     49                     from all_gather.cu(0):
#  >> 50    /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos
#           8-cascadelake/intel-19.1.2.254/cuda-10.2.89-wulkkucah66aloi4zdf4hutj
#           7iuwwx2v/bin/../targets/x86_64-linux/include/crt/host_config.h(110):
#            error: #error directive: -- unsupported ICC configuration! Only ICC
#            15.0, ICC 16.0, ICC 17.0, ICC 18.0 and ICC 19.0 on Linux x86_64 are
#            supported!
#     51      #error -- unsupported ICC configuration! Only ICC 15.0, ICC 16.0, 
#           ICC 17.0, ICC 18.0 and ICC 19.0 on Linux x86_64 are supported!
#     52       ^
#     53 

declare -xr INTEL_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='nccl@2.7.8-1'
declare -xr SPACK_COMPILER='intel@19.1.2.254'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=70'
declare -xr SPACK_DEPENDENCIES="^cuda@10.2.89/$(spack find --format '{hash:7}' cuda@10.2.89 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types nccl@2.7.8-1 % intel@19.1.2.254 +cuda cuda_arch=70 ^cuda@10.2.89
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all nccl@2.7.8-1 % intel@19.1.2.254 +cuda cuda_arch=70 ^cuda@10.2.89
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'cmake@3.18.2.sh'

sleep 60
