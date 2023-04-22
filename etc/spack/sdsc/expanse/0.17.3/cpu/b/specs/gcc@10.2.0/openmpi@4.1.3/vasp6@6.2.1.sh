#!/usr/bin/env bash

#SBATCH --job-name=vasp6@6.2.1
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=01:00:00
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
#declare -xr COMPILER_MODULE='gcc/10.2.0'
#declare -xr MPI_MODULE='openmpi/4.1.3'
#declare -xr CUDA_MODULE='cuda/11.2.2'
#declare -xr CMAKE_MODULE='cmake/3.21.4'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
#module load "${COMPILER_MODULE}"
#module load "${MPI_MODULE}"
#module load "${CUDA_MODULE}"
#module load "${CMAKE_MODULE}"
module list

#2 errors found in build log:
#     138    gcc -E -P -C -w fock_glb.F >fock_glb.f90 -DMPI -DMPI_BLOCK=8000 -Du
#            se_collective -DCACHE_SIZE=4000 -Davoidalloc -Duse_bse_te -Dtbdyn -
#            Duse_shmem -DHOST=\"LinuxGNU\" -Dvasp6 -DscaLAPACK -Dsol_compat -DN
#            GZhalf
#     139    mpif90 -fopenmp -ffree-form -ffree-line-length-none -w -fallow-argu
#            ment-mismatch -O2 -I/cm/shared/apps/spack/0.17.3/cpu/a/opt/spack/li
#            nux-rocky8-zen2/gcc-10.2.0/fftw-3.3.10-qogw3ssyk3cwr5qiwik3eetj22cr
#            yewg/include  -c fock_glb.f90
#     140    fock_glb.f90:325:31:
#     141
#     142      325 | !$   INTEGER(KIND=OMP_LOCK_KIND), POINTER :: OMP_LCK1(:),OM
#            P_LCK2(:)
#     143          |                               1
#  >> 144    Error: Symbol 'omp_lock_kind' at (1) has no IMPLICIT type; did you
#            mean 'mpi_count_kind'?
#     145    make[2]: *** [makefile:181: fock_glb.o] Error 1
#     146    make[2]: Leaving directory '/scratch/spack_cpu/job_21114617/spack-s
#            tage/spack-stage/spack-stage-vasp6-6.2.1-5y35k7dgxh6pnpxcyztndscnw6
#            dl2xg3/spack-src/build/std'
#  >> 147    cp: cannot stat 'vasp': No such file or directory
#     148    make[1]: *** [makefile:146: all] Error 1
#     149    make[1]: Leaving directory '/scratch/spack_cpu/job_21114617/spack-s
#            tage/spack-stage/spack-stage-vasp6-6.2.1-5y35k7dgxh6pnpxcyztndscnw6
#            dl2xg3/spack-src/build/std'
#     150    make: *** [makefile:17: std] Error 2

# ==> Error: ProcessError: Command exited with status 77:
#    '/scratch/spack_cpu/job_21114756/spack-stage/spack-stage/spack-stage-popt-1.16-mr4trumi3p2tfdyfurp226nvsy7uruom/spack-src/configure' '--prefix=/cm/shared/apps/spa
#ck/0.17.3/cpu/a/opt/spack/linux-rocky8-zen2/intel-19.1.3.304/popt-1.16-mr4trumi3p2tfdyfurp226nvsy7uruom'
#
#2 errors found in build log:
#     10    checking for gawk... gawk
#     11    checking whether make sets $(MAKE)... yes
#     12    checking whether to enable maintainer-specific portions of Makefiles
#           ... no
#     13    checking for style of include used by make... GNU
#     14    checking for gcc... /cm/shared/apps/spack/0.17.3/cpu/a/lib/spack/env
#           /intel/icc
#     15    checking for C compiler default output file name...
#  >> 16    configure: error: in `/scratch/spack_cpu/job_21114756/spack-stage/sp
#           ack-stage/spack-stage-popt-1.16-mr4trumi3p2tfdyfurp226nvsy7uruom/spa
#           ck-src':
#  >> 17    configure: error: C compiler cannot create executables
#     18    See `config.log' for more details.

# solvation.o: In function `__pot_k_MOD_vcorrection':
# solvation.f90:(.text+0x72ad): undefined reference to `m_sum_s_'
# solvation.f90:(.text+0x72e8): undefined reference to `m_sum_s_'
# collect2: error: ld returned 1 exit status

declare -xr SPACK_PACKAGE='vasp6@6.2.1'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~cuda ~openmp +scalapack +shmem ~vaspsol'
declare -xr SPACK_DEPENDENCIES="^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^netlib-scalapack@2.1.0/$(spack find --format '{hash:7}' netlib-scalapack@2.1.0 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'gamess@2021.09.sh'

sleep 30
