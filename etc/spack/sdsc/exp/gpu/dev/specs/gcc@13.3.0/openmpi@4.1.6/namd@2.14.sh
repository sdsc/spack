#!/usr/bin/env bash

#SBATCH --job-name=namd@2.14
#SBATCH --account=use300
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

declare -xr SPACK_MAJOR='0'
declare -xr SPACK_MINOR='21'
declare -xr SPACK_REVISION='2'
declare -xr SPACK_VERSION="${SPACK_MAJOR}.${SPACK_MINOR}.${SPACK_REVISION}"
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_VERSION='dev'
declare -xr SPACK_INSTANCE_DIR='/home/mkandes/software/spack/repos/sdsc/gpu'

declare -xr TMPDIR="${SLURM_TMPDIR}/spack-stage"
declare -xr TMP="${TMPDIR}"

echo "${UNIX_TIME} ${LOCAL_TIME} ${SLURM_JOB_ID} ${JOB_SCRIPT_MD5} ${JOB_SCRIPT_SHA256} ${JOB_SCRIPT_NUMBER_OF_LINES} ${JOB_SCRIPT}"
cat  "${JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

#==> namd: Executing phase: 'edit'
#==> [2025-02-03-18:25:07.339820] '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-13.3.0-ot32neovzvypcfvs6axkk4vndxj3lqe6/bin/gcc' '-dumpversion'
#==> [2025-02-03-18:25:07.356600] Copying arch/Linux-x86_64.base to arch/linux-x86_64.base
#==> [2025-02-03-18:25:07.357158] Copying arch/Linux-x86_64.fftw3 to arch/linux-x86_64.fftw3
#==> [2025-02-03-18:25:07.357687] Copying arch/Linux-x86_64.tcl to arch/linux-x86_64.tcl
#==> [2025-02-03-18:25:07.358212] FILTER FILE: arch/linux-x86_64.tcl [replacing "-ltcl8\.5"]
#==> [2025-02-03-18:25:07.359382] Copying arch/Linux-x86_64.cuda to arch/linux-x86_64.cuda
#==> [2025-02-03-18:25:07.359840] FILTER FILE: arch/linux-x86_64.cuda [replacing "^CUDADIR=.*$"]
#==> [2025-02-03-18:25:07.360683] './config' 'linux-x86_64-spack' '--charm-base' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/charmpp-6.10.2-qd5zna5evidmqjhm277regcvryscosmg' '--with-fftw3' '--fftw-prefix' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/fftw-3.3.10-lszeeshr5pt6afcgeu52z4u2egt3vsp7' '--with-tcl' '--tcl-prefix' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/tcl-8.6.12-5zxpqlfc3rhak7ykmkypjmxjfcsdt7qf' '--with-cuda' '--cuda-prefix' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/cuda-12.6.3-guub3z6c6k7zgb3qv3vdngxr6zu5mhzy' '--cuda-gencode' 'arch=compute_70,code=sm_70' '--cuda-gencode' 'arch=compute_80,code=sm_80' '--cuda-gencode' 'arch=compute_90,code=sm_90'
#
#Selected arch file arch/linux-x86_64-spack.arch contains:
#
#NAMD_ARCH = linux-x86_64
#CHARMARCH = mpi-linux-x86_64-smp
#CXX = /home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-13.3.0-ot32neovzvypcfvs6axkk4vndxj3lqe6/bin/g++ -std=c++11
#CXXOPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
#CC = /home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-13.3.0-ot32neovzvypcfvs6axkk4vndxj3lqe6/bin/gcc
#COPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
#
#ERROR: MPI-based Charm++ arch  is not compatible with CUDA NAMD.
#ERROR: CUDA builds require non-MPI SMP or multicore Charm++ arch for reasonable performance.
#
#Consider ucx-smp or verbs-smp (InfiniBand), gni-smp (Cray), or multicore (single node).

declare -xr SPACK_PACKAGE='namd@2.14'
declare -xr SPACK_COMPILER='gcc@13.3.0'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=70,80,90 fftw=3 interface=tcl ~single_node_gpu'
declare -xr SPACK_MPI='openmpi@4.1.6'
declare -xr SPACK_DEPENDENCIES="^charmpp@6.10.2/$(spack find --format '{hash:7}' charmpp@6.10.2 % ${SPACK_COMPILER} backend=mpi +cuda ^${SPACK_MPI} ^cuda@12.6.3/$(spack find --format '{hash:7}' cuda@12.6.3 % ${SPACK_COMPILER})) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp)"
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

wget https://www.ks.uiuc.edu/Research/namd/2.14/download/946183/NAMD_2.14_Source.tar.gz
time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all --reuse "$(echo ${SPACK_SPEC})"
sleep 600
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi
