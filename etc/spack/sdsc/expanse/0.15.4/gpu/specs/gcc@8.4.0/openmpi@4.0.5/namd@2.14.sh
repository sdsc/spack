#!/usr/bin/env bash

#SBATCH --job-name=namd@2.14
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


#=> namd: Executing phase: 'edit''./config' 'linux-x86_64-spack' '--charm-base' ==> [2021-10-01-13:43:57.157869] '/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-skylake_avx512/gcc-8.3.1/gcc-8.4.0-jnau2tdwuhikrduudobatvvwun5ucnxh/bin/gcc' '-dumpversion'-gfmbarrqnnsgc5wtb65irtfik5kdertr' '--with-fftw3' ==> [2021-10-01-13:43:57.162719] Copying arch/Linux-x86_64.base to arch/linux-x86_64.base==> [2021-10-01-13:43:57.163442] Copying arch/Linux-x86_64.fftw3 to arch/linux-x86_64.fftw3==> [2021-10-01-13:43:57.164279] Copying arch/Linux-x86_64.cuda to arch/linux-x86_64.cuda==> [2021-10-01-13:43:57.165268] FILTER FILE: arch/linux-x86_64.cuda [replacing "^CUDADIR=.*$"]==> [2021-10-01-13:43:57.165919] './config' 'linux-x86_64-spack' '--charm-base' '/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-skylake_avx512/gcc-8.4.0/charmpp-6.10.2-gfmbarrqnnsgc5wtb65irtfik5kdertr' '--with-fftw3' '--fftw-prefix' '/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-skylake_avx512/gcc-8.4.0/fftw-3.3.8-frorpgkq4hewylsrofqpvmfw2sw7uglp' '--without-tcl' '--without-python' '--with-cuda' '--cuda-prefix' '/home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-skylake_avx512/gcc-8.4.0/cuda-10.2.89-yp465scb7fvymjopcpf3bose34d2gkng'
#age/spack-stage-namd-2.14-nlavwiztuotppbz53plnn7v3txyxacmu/spack-build-out.txt
#Selected arch file arch/linux-x86_64-spack.arch contains:
#
#NAMD_ARCH = linux-x86_64
#CHARMARCH = mpi-linux-x86_64
#CXX = /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-skylake_avx512/gcc-8.3.1/gcc-8.4.0-jnau2tdwuhikrduudobatvvwun5ucnxh/bin/g++ -std=c++11
#CXXOPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=skylake-avx512 -mtune=skylake-avx512
#CC = /home/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-skylake_avx512/gcc-8.3.1/gcc-8.4.0-jnau2tdwuhikrduudobatvvwun5ucnxh/bin/gcc
#COPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=skylake-avx512 -mtune=skylake-avx512
#
#ERROR: MPI-based Charm++ arch  is not compatible with CUDA NAMD.
#ERROR: Non-SMP Charm++ arch  is not compatible with CUDA NAMD.
#ERROR: CUDA builds require non-MPI SMP or multicore Charm++ arch for reasonable performance.
#
#Consider ucx-smp or verbs-smp (InfiniBand), gni-smp (Cray), or multicore (single node).

declare -xr SPACK_PACKAGE='namd@2.14'
declare -xr SPACK_COMPILER='gcc@8.4.0'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=70'
declare -xr SPACK_DEPENDENCIES="^cuda@10.2.89 ^charmpp@6.10.2/$(spack find --format '{hash:7}' charmpp@6.10.2 % ${SPACK_COMPILER}) ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} ~mpi ~openmp)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types namd@2.14 % gcc@8.4.0 +cuda cuda_arch=70 "^cuda@10.2.89 ^charmpp@6.10.2/$(spack find --format '{hash:7}' charmpp@6.10.2 % ${SPACK_COMPILER}) ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} ~mpi ~openmp)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all namd@2.14 % gcc@8.4.0 +cuda cuda_arch=70 "^cuda@10.2.89 ^charmpp@6.10.2/$(spack find --format '{hash:7}' charmpp@6.10.2 % ${SPACK_COMPILER}) ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} ~mpi ~openmp)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
