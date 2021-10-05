#!/usr/bin/env bash

#SBATCH --job-name=tau@2.29
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


#==> Installing tau
#==> No binary for tau found: installing from source
#==> Fetching https://spack-llnl-mirror.s3-us-west-2.amazonaws.com/_source-cache/archive/14/146be769a23c869a7935e8fa5ba79f40ba36b9057a96dda3be6730fc9ca86086.tar.gz
#==> tau: Executing phase: 'install'
#==> Error: ProcessError: Command exited with status 2:
#    'make' '-j10' 'install'
#
#8 errors found in build log:
#     92     TAU: PDT: Using binary rewriting capabilities from PEBIL in tau_peb
#            il_rewrite
#     93     ====================================================
#     94      Copy /tmp/mkandes/spack-stage/spack-stage-tau-2.29-ppgavtgeq2hmseg
#            t7ehlzzszxni7mti4/spack-src/tools/src/contrib/CubeReader.jar to /ho
#            me/mkandes/cm/shared/apps/spack/0.15.4/gpu/opt/spack/linux-centos8-
#            skylake_avx512/gcc-8.4.0/tau-2.29-ppgavtgeq2hmsegt7ehlzzszxni7mti4/
#            x86_64/lib
#     95     ====================================================
#     96     ... done
#     97     #*******************************************************************
#            ****
#  >> 98     grep: ./utils/FixMakefile.info: No such file or directory
#  >> 99     grep: ./utils/FixMakefile.sed: No such file or directory
#     100    NOTE: Enabling power measurements using PAPI's Perf RAPL interface 
#            ***
#     101    NOTE: Saving configuration environment to /tmp/mkandes/spack-stage/
#            spack-stage-tau-2.29-ppgavtgeq2hmsegt7ehlzzszxni7mti4/spack-src/.co
#            nfigure_env/2a78bb4cac461efa1fb6b1bcdee7044b
#     102    NOTE: Enabled Profiling. Compiling with -DPROFILING_ON
#     103    NOTE: Building POSIX I/O wrapper
#     104    NOTE: GNU gfortran compiler specific options used
#     105    NOTE: Using PAPI interface for Hardware Performance Counters ***
#
#     ...
#
#     227    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-ta
#            u-2.29-ppgavtgeq2hmsegt7ehlzzszxni7mti4/spack-src/plugins'
#     228    make[1]: Entering directory '/tmp/mkandes/spack-stage/spack-stage-t
#            au-2.29-ppgavtgeq2hmsegt7ehlzzszxni7mti4/spack-src/examples/instrum
#            ent'
#     229    /bin/rm -f simple.o simple


declare -xr SPACK_PACKAGE='tau@2.29'
declare -xr SPACK_COMPILER='gcc@8.4.0'
declare -xr SPACK_VARIANTS='~adios2 +binutils ~comm ~craycnl +cuda +fortran ~gasnet +io +libdwarf +libelf +libunwind ~likwid +mpi ~ompt ~opari ~openmp +otf2 +papi +pdt ~phase ~ppc64le ~profileparam +pthreads ~python ~scorep ~shmem ~sqlite ~x86_64'
declare -xr SPACK_DEPENDENCIES="^mvapich2@2.3.4/$(spack find --format '{hash:7}' mvapich2@2.3.4 % ${SPACK_COMPILER}) ^papi@6.0.0.1/$(spack find --format '{hash:7}' papi@6.0.0.1 % ${SPACK_COMPILER})"
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
