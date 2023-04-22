#!/usr/bin/env bash

#SBATCH --job-name=openblas@0.3.18-omp
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=00:30:00
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
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

#==> Error: ProcessError: Command exited with status 2:
#    'make' '-j16' 'CC=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/lib/spack/env/aocc/clang' 'FC=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/lib/spack/env/aocc/flan
#g' 'MAKE_NB_JOBS=0' 'ARCH=x86_64' 'TARGET=ZEN' 'USE_LOCKING=1' 'USE_OPENMP=1' 'USE_THREAD=1' 'INTERFACE64=1' 'RANLIB=ranlib' 'libs' 'netlib' 'shared'
#
#2 errors found in build log:
#     7188    -Wl,--whole-archive ../libopenblas_zenp-r0.3.18.a -Wl,--no-whole-a
#             rchive \
#     7189    -Wl,-soname,libopenblas.so.0 -lm -lpthread -lm -lpthread
#     7190    clang-13: warning: argument unused during compilation: '-Mrecursiv
#             e' [-Wunused-command-line-argument]
#     7191    clang-13: warning: argument unused during compilation: '-Kieee' [-
#             Wunused-command-line-argument]
#     7192    clang-13: warning: argument unused during compilation: '-i8' [-Wun
#             used-command-line-argument]
#     7193    /home/mkandes/cm/shared/apps/spack/0.17.2/cpu/lib/spack/env/aocc/c
#             lang -O2 -DSMALL_MATRIX_OPT -DMAX_STACK_ALLOC=2048 -DUSE_LOCKING -
#             fopenmp -Wall -m64 -DF_INTERFACE_FLANG  -fPIC -DSMP_SERVER -DUSE_O
#             PENMP -DNO_WARMUP -DMAX_CPU_NUMBER=128 -DMAX_PARALLEL_NUMBER=1 -DB
#             UILD_SINGLE=1 -DBUILD_DOUBLE=1 -DBUILD_COMPLEX=1 -DBUILD_COMPLEX16
#             =1 -DVERSION=\"0.3.18\" -msse3 -msse4.1 -mavx -mavx2 -mavx2 -UASMN
#             AME -UASMFNAME -UNAME -UCNAME -UCHAR_NAME -UCHAR_CNAME -DASMNAME= 
#             -DASMFNAME=_ -DNAME=_ -DCNAME= -DCHAR_NAME=\"_\" -DCHAR_CNAME=\"\"
#              -DNO_AFFINITY -I..  -w -o linktest linktest.c ../libopenblas_zenp
#             -r0.3.18.so -L/usr/lib/gcc/x86_64-redhat-linux/8 -L/usr/lib/gcc/x8
#             6_64-redhat-linux/8/../../../../lib64 -L/lib/../lib64 -L/usr/lib/.
#             ./lib64 -L/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/
#             linux-rocky8-zen/gcc-8.5.0/aocc-3.2.0-io3s466wsnnichqc2o2rikbuloev
#             5bmq/bin/../lib -L/lib -L/usr/lib -Wl,-rpath,/home/mkandes/cm/shar
#             ed/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/aocc
#             -3.2.0-io3s466wsnnichqc2o2rikbuloev5bmq/bin/../lib -Wl,-rpath,/hom
#             e/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-z
#             en/gcc-8.5.0/aocc-3.2.0-io3s466wsnnichqc2o2rikbuloev5bmq/bin/../li
#             b  -lflangmain -lflang -lflangrti -lpgmath -lquadmath -lomp -lm -l
#             rt -lpthread -lomp -lpthread -lc  -lflang && echo OK.
#  >> 7194    ld.lld: error: ../libopenblas_zenp-r0.3.18.so: undefined reference
#              to __kmpc_omp_task_alloc_with_deps [--no-allow-shlib-undefined]
#  >> 7195    clang-13: error: linker command failed with exit code 1 (use -v to
#              see invocation)
#     7196    make[1]: *** [Makefile:180: ../libopenblas_zenp-r0.3.18.so] Error 
#             1
#     7197    make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-o
#             penblas-0.3.18-dlnlqbqdo4b6nbdoewdswyeupsq4mskg/spack-src/exports'
#     7198    make: *** [Makefile:122: shared] Error 2

declare -xr SPACK_PACKAGE='openblas@0.3.18'
declare -xr SPACK_COMPILER='aocc@3.2.0'
declare -xr SPACK_VARIANTS='~bignuma ~consistent_fpcsr ~ilp64 +locking +pic +shared threads=openmp'
declare -xr SPACK_DEPENDENCIES=''
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS}"

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

sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 30
