#!/usr/bin/env bash

#SBATCH --job-name=charmpp@6.10.2
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-gpu-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=93G
#SBATCH --gpus=1
#SBATCH --time=48:00:00
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

# unsatisfiable, conflicts are:
#  A conflict was triggered
#  condition(322)
#  condition(331)
#  condition(337)
#  condition(338)
#  conflict("charmpp",337,338)
#  root("charmpp")
#  variant_condition(322,"charmpp","backend")
#  variant_condition(331,"charmpp","smp")
#  variant_set("charmpp","backend","multicore")
#  variant_set("charmpp","smp","True")

# ==> [2023-04-12-11:06:06.456442] './build' 'charm++' 'multicore-linux-x86_64' 'gcc' 'gfortran' '-j10' '--destination=/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/b/opt/spack/linux-rocky8-skylake_avx512/gcc-10.2.0/charmpp-6.10.2-g3qprv4xxcjwqxel4b5pcv42elw3w7lh' 'omp' 'cuda' '--build-shared' '--with-production'
#checking for CUDA toolkit directory
#CUDA_DIR=/cm/local/apps/cuda
#Selected Compiler: gcc
#Selected Options:  gfortran omp cuda
#OpenMP support should be built in SMP mode

declare -xr SPACK_PACKAGE='charmpp@6.10.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='backend=multicore build-target=charm++ +cuda ~omp ~papi pmi=none +production ~pthreads +shared ~smp ~syncft ~tcp ~tracing'
declare -xr SPACK_DEPENDENCIES="^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types charmpp@6.10.2 % gcc@10.2.0 backend=multicore build-target=charm++ +cuda ~omp ~papi pmi=none +production ~pthreads +shared ~smp ~syncft ~tcp ~tracing "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all charmpp@6.10.2 % gcc@10.2.0 backend=multicore build-target=charm++ +cuda ~omp ~papi pmi=none +production ~pthreads +shared ~smp ~syncft ~tcp ~tracing "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'namd@2.14.sh'

sleep 30
