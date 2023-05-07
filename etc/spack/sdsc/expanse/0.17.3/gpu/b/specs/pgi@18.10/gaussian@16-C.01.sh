#!/usr/bin/env bash

#SBATCH --job-name=gaussian@16-C.01
#SBATCH --account=use300
##SBATCH --reservation=root_63
#SBATCH --partition=ind-gpu-shared
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
declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}/spack-stage"
declare -xt TMP="${TMPDIR}"

declare -xr SLURM_JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr SLURM_JOB_MD5SUM="$(md5sum ${SLURM_JOB_SCRIPT})"

declare -xr SCHEDULER_MODULE='slurm'
declare -xr COMPILER_MODULE='pgi/18.10'
declare -xr CUDA_MODULE='cuda/10.0.130'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT_DIR}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_MODULE}"
module load "${CUDA_MODULE}"
module list

# make[1]: Entering directory '/tmp/mkandes/spack-stage/spack-stage-gaussian-16-C.01-kkwrnvvs2mzwultjdxtmw26nvacw3j4r/spack-src/g16/temputil'
# cc -g  -I/tmp/mkandes/spack-stage/spack-stage-gaussian-16-C.01-kkwrnvvs2mzwultjdxtmw26nvacw3j4r/spack-src/g16 -DDEFMAXRES=25000 -DDEFMAXSEC=2500 -DI64 -DP64 -DPACK64 -DUSE_I2 -DGAUSS_PAR -DGAUSS_THPAR -D_OPENMP_ -D_OPENMP_MM_ -DCHECK_ARG_OVERLAP -DDEFMAXSHL=250000 -DDEFMAXATM=250000 -D_EM64T_ -DNO_SBRK '-DX86_TYPE=S' -DDEFMAXNZ=250000 -DDEFNREPFD=32 -DDEFNVDIM=257 -DR4ETIME -DDEFARCREC=1024 -DMERGE_LOOPS -D_I386_ -DLITTLE_END -DUSING_F2C -DSTUPID_ATLAS -DDEFMAXXCVAR=150 -DDEFMAXIOP=200 -DDEFMAXCOORDINFO=32 -DDEFMAXSUB=80 -DDEFMAXCHR=1024 -DDEFMOMEGA=5 -DDEFNOMEGA=6 -DDEFMAXXCNAME=25 -DDEFLMAX=13 -DDEFMINB1P=100000000 -DDEFXGN3MIN=1 -DDEFISEC=16 -DDEFJSEC=512 -DDEFKSEC=128 -DDEFN3MIN=10 -DDEFNBOMAXBAS=10000 -DDEFMAXHEV=2000 -DDEFCACHE=88 -DDEFMAXLECP=10 -DDEFMAXFUNIT=5 -DDEFMAXFFILE=10000 -DDEFMAXFPS=1300 -DDEFMAXINFO=200 -DDEFMAXOP=384 -DDEFMAXTIT=100 -DDEFMAXRTE=4000 -DDEFMAXREDTYPE=3 -DDEFMAXREDINDEX=4 -DDEFMAXOV=500 -DDEFMXDNXC=8 -DDEFMXTYXC=10 -DDEFICTDBG=0 -D_ALIGN_CORE_ -DCA1_DGEMM -DCA2_DGEMM -DCAB_DGEMM -DLV_DSP -DO_BKSPEF -DSETCDMP_OK -DDEFMXTS=2500 -DDEFMXBOND=12 -DDEFMXSPH=250 -DDEFMXINV=2500  -DDEFMXSLPAR=300 -DDEFMXSATYP=4 -DGCONJG=DCONJG -DGCMPLX=DCmplx -DGREAL=DREAL -DGIMAG=DIMAG -DEXT_LSEEK -DAPPEND_ACC     -O3 -ffast-math -funroll-loops -fexpensive-optimizations  -Mcuda=cuda10.0,flushz,unroll,nollvm,fma -acc=nowait -ta=tesla:cuda10.0,cc35,cc60,cc70,flushz,nollvm,unroll,fma,v32mode  -c bsd/mdutil.c
# cc: error: unrecognized command line option '-Mcuda=cuda10.0,flushz,unroll,nollvm,fma'
# cc: error: unrecognized command line option '-acc=nowait'
# cc: error: unrecognized command line option '-ta=tesla:cuda10.0,cc35,cc60,cc70,flushz,nollvm,unroll,fma,v32mode'
# make[1]: *** [../bsd/g16.make:778: mdutil.o] Error 1
# make[1]: Leaving directory '/tmp/mkandes/spack-stage/spack-stage-gaussian-16-C.01-kkwrnvvs2mzwultjdxtmw26nvacw3j4r/spack-src/g16/temputil'
# ar rlv ../util.a mdutil.o
# ar: creating ../util.a
# ar: mdutil.o: No such file or directory
# endif
# rm mdutil.o
# rm: cannot remove 'mdutil.o': No such file or directory

# pgcc-Error-Please run makelocalrc to complete your installation
# make: *** [bsd/g16.make:621: gau-fsplit] Error 1
# ls -s gau-fsplit gau-cpp
# ls: cannot access 'gau-fsplit': No such file or directory
# ls: cannot access 'gau-cpp': No such file or directory

# make[1]: pgf77: Command not found
# make[1]: *** [../bsd/g16.make:184: a2nucf.o] Error 127

# In file included from /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/pgi-18.10-b62v6j55yvlmqggwk26oyqvhfev6a45l/linux86-64/2018/cuda/10.0/include/cuda_runtime.h:83,
#                 from ./pgaccSN0ule4dBmOls.gpu:1:
# /home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/pgi-18.10-b62v6j55yvlmqggwk26oyqvhfev6a45l/linux86-64/2018/cuda/10.0/include/crt/host_config.h:127:2: error: #error -- unsupported GNU version! gcc versions later than 7 are not supported!
# error -- unsupported GNU version! gcc versions later than 7 are not supported!
#  ^~~~~
# PGF90-S-0155-Compiler failed to translate accelerator region (see -Minfo messages): Device compiler exited with error status code (aadd.f: 1)
#  0 inform,   0 warnings,   1 severes, 0 fatal for 
#  Timing stats:
#    vectorize               16 millisecs   100%
#    Total time              16 millisecs
# make: *** [../bsd/g16.make:184: aadd.o] Error 2

declare -xr PGROUPD_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr LM_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='gaussian@16-C.01' # 16-C.02 supports cuda_arch=80
declare -xr SPACK_COMPILER='pgi@18.10'
declare -xr SPACK_VARIANTS='~binary +cuda cuda_arch=70'
declare -xr SPACK_DEPENDENCIES="^cuda@10.0.130/$(spack find --format '{hash:7}' cuda@10.0.130 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types gaussian@16-C.01 % pgi@18.10 ~binary +cuda cuda_arch=70 "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all gaussian@16-C.01 % pgi@18.10 ~binary +cuda cuda_arch=70 "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
