#!/usr/bin/env bash

#SBATCH --job-name=namd@2.14
#SBATCH --account=use300
#SBATCH --reservation=root_73
#SBATCH --clusters=expanse
#SBATCH --partition=ind-gpu-shared
#SBATCH --qos=gpu-unlim
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=92G
#SBATCH --gpus=1
#SBATCH --time=00:30:00
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
declare -xr SPACK_SYSTEM_NAME='exp'
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_VERSION='dev'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}/${SPACK_INSTANCE_VERSION}"

declare -xr TMPDIR="${SLURM_TMPDIR}/spack-stage"
declare -xr TMP="${TMPDIR}"

echo "${UNIX_TIME} ${LOCAL_TIME} ${SLURM_JOB_ID} ${JOB_SCRIPT_MD5} ${JOB_SCRIPT_SHA256} ${JOB_SCRIPT_NUMBER_OF_LINES} ${JOB_SCRIPT}"
cat  "${JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

#==> namd: Executing phase: 'edit'
#==> [2025-01-08-10:39:38.127950] '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-13.3.0-ot32neovzvypcfvs6axkk4vndxj3lqe6/bin/gcc' '-dumpversion'
#==> [2025-01-08-10:39:38.145253] Copying arch/Linux-x86_64.base to arch/linux-x86_64.base
#==> [2025-01-08-10:39:38.145795] Copying arch/Linux-x86_64.fftw3 to arch/linux-x86_64.fftw3
#==> [2025-01-08-10:39:38.146179] Copying arch/Linux-x86_64.tcl to arch/linux-x86_64.tcl
#==> [2025-01-08-10:39:38.146597] FILTER FILE: arch/linux-x86_64.tcl [replacing "-ltcl8\.5"]
#==> [2025-01-08-10:39:38.147606] Copying arch/Linux-x86_64.cuda to arch/linux-x86_64.cuda
#==> [2025-01-08-10:39:38.148102] FILTER FILE: arch/linux-x86_64.cuda [replacing "^CUDADIR=.*$"]
#==> [2025-01-08-10:39:38.148980] './config' 'linux-x86_64-spack' '--charm-base' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/charmpp-6.10.2-pkfynxzasawfo6t4nehep6lmtc7rb72d' '--with-fftw3' '--fftw-prefix' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/fftw-3.3.10-lszeeshr5pt6afcgeu52z4u2egt3vsp7' '--with-tcl' '--tcl-prefix' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/tcl-8.6.12-5zxpqlfc3rhak7ykmkypjmxjfcsdt7qf' '--with-cuda' '--cuda-prefix' '/home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelake/gcc-13.3.0/cuda-12.6.3-guub3z6c6k7zgb3qv3vdngxr6zu5mhzy' '--cuda-gencode' 'arch=compute_70,code=sm_70' '--cuda-gencode' 'arch=compute_80,code=sm_80' '--cuda-gencode' 'arch=compute_90,code=sm_90'
#
#Selected arch file arch/linux-x86_64-spack.arch contains:
#
#NAMD_ARCH = linux-x86_64
#CHARMARCH = verbs-linux-x86_64
#CXX = /home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-13.3.0-ot32neovzvypcfvs6axkk4vndxj3lqe6/bin/g++ -std=c++11
#CXXOPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
#CC = /home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-13.3.0-ot32neovzvypcfvs6axkk4vndxj3lqe6/bin/gcc
#COPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
#
#ERROR: Non-SMP Charm++ arch  is not compatible with CUDA NAMD.
#ERROR: CUDA builds require non-MPI SMP or multicore Charm++ arch for reasonable performance.
#
#Consider ucx-smp or verbs-smp (InfiniBand), gni-smp (Cray), or multicore (single node).


# [mkandes@login02 gpu]$ spack spec -l namd@2.14 % gcc@11.5.0 +cuda fftw=3 interface=tcl ~single_node_gpu cuda_arch=70,80,90 ^cuda@11.8.0
#==> Error: concretization failed for the following reasons:
#
#   1. Cannot select a single "version" for package "cuda"
#   2. Cannot satisfy 'cuda@:11.8'
#   3. Cannot satisfy 'cuda@12.0:'
#   4. Cannot satisfy 'cuda@11.8.0'
#   5. namd: '%gcc@13:' conflicts with '+cuda ^cuda@:12.1~allow-unsupported-compilers'
#   6. namd: '%gcc@12:' conflicts with '+cuda ^cuda@:11.8~allow-unsupported-compilers'
#   7. Cannot satisfy 'cuda@12.0:'
#        required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   8. Cannot satisfy 'cuda@11.8.0'
#        required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   9. namd: '%gcc@13:' conflicts with '+cuda ^cuda@:12.1~allow-unsupported-compilers'
#        required because conflict applies to spec +cuda ^cuda@:12.1~allow-unsupported-compilers 
#          required because namd depends on cuda@9.0: when cuda_arch=70 
#            required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#          required because namd depends on cuda@11.0: when cuda_arch=80 
#          required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd depends on cuda@8.0.61: when @2.13:+cuda 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because conflict is triggered when %gcc@13: 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   10. namd: '%gcc@12:' conflicts with '+cuda ^cuda@:11.8~allow-unsupported-compilers'
#        required because conflict is triggered when %gcc@12: 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because conflict applies to spec +cuda ^cuda@:11.8~allow-unsupported-compilers 
#          required because namd depends on cuda@9.0: when cuda_arch=70 
#            required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#          required because namd depends on cuda@11.0: when cuda_arch=80 
#          required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd depends on cuda@8.0.61: when @2.13:+cuda 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   11. Cannot satisfy 'cuda@9.0:' and 'cuda@12.0:
#        required because namd depends on cuda@9.0: when cuda_arch=70 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   12. Cannot satisfy 'cuda@8.0.61:' and 'cuda@12.0:
#        required because namd depends on cuda@8.0.61: when @2.13:+cuda 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   13. Cannot satisfy 'cuda@12.0:' and 'cuda@11.8.0
#        required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   14. Cannot satisfy 'cuda@11.8.0' and 'cuda@12.0:
#        required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#   15. Cannot satisfy 'cuda@11.0:' and 'cuda@12.0:
#        required because namd depends on cuda@11.0: when cuda_arch=80 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#        required because namd depends on cuda@12.0: when cuda_arch=90 
#          required because namd@2.14%gcc@11.5.0+cuda~single_node_gpu cuda_arch=70,80,90 fftw=3 interface=tcl ^cuda@11.8.0 requested explicitly 
#[mkandes@login02 gpu]$

#      455    /home/mkandes/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-
#            cascadelake/gcc-13.3.0/cuda-12.6.3-guub3z6c6k7zgb3qv3vdngxr6zu5mhzy
#            /bin/nvcc -Xcompiler "-m64" -O3 --maxrregcount 48 -gencode arch=com
#            pute_70,code=sm_70 -gencode arch=compute_80,code=sm_80 -gencode arc
#            h=compute_90,code=sm_90 -DNAMD_CUDA -I. -I.rootdir/cub -I/home/mkan
#            des/software/spack/repos/sdsc/gpu/opt/spack/linux-rocky8-cascadelak
#            e/gcc-13.3.0/cuda-12.6.3-guub3z6c6k7zgb3qv3vdngxr6zu5mhzy/include  
#            -use_fast_math -Xptxas -v -o obj/ComputePmeCUDAKernel.o -c `echo sr
#            c/`ComputePmeCUDAKernel.cu
#  >> 456    src/ComputeNonbondedCUDAKernel.cu(12): error: texture is not a temp
#            late
#     457      texture<unsigned int, 1, cudaReadModeElementType> tex_exclusions;
#     458      ^
#     459    
#  >> 460    src/ComputeNonbondedCUDAKernel.cu(44): error: identifier "cudaBindT
#            exture" is undefined
#     461        cudaBindTexture(
#     462        ^
#     463    
#  >> 464    src/ComputeNonbondedCUDAKernel.cu(56): error: texture is not a temp
#            late
#     465      texture<float2, 1, cudaReadModeElementType> lj_table;
#     466      ^
#     467

declare -xr SPACK_PACKAGE='sdsc.namd@2.14'
declare -xr SPACK_COMPILER='gcc@11.5.0'
declare -xr SPACK_VARIANTS='+cuda fftw=3 interface=tcl ~single_node_gpu cuda_arch=70,80'
declare -xr SPACK_DEPENDENCIES="^cuda@11.8.0/$(spack find --format '{hash:7}' cuda@11.8.0 % ${SPACK_COMPILER}) ^charmpp@6.10.2/$(spack find --format '{hash:7}' charmpp@6.10.2 % ${SPACK_COMPILER} +cuda backend=verbs) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp)"
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
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

time -p spack mirror create --dependencies --directory "${HOME}/software/spack/caches/${SPACK_VERSION}/${SPACK_SYSTEM_NAME}/${SPACK_INSTANCE_NAME}/dev" "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack mirror create failed.'
  exit 1
fi

time -p spack buildcache push "${HOME}/software/spack/caches/${SPACK_VERSION}/${SPACK_SYSTEM_NAME}/${SPACK_INSTANCE_NAME}/dev" "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack buildcache push failed.'
  exit 1
fi
