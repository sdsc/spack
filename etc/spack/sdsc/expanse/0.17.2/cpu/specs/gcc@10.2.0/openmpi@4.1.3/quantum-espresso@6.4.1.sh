#!/usr/bin/env bash

#SBATCH --job-name=quantum-espresso@6.4.1
#SBATCH --account=use300
#SBATCH --reservation=root_63
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.2'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR="/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

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

# QE v6.4.1 concretizes with cmake even if ~cmake? Maybe current spack 
# package does not remove the dependency when ~cmake is set explicitly. 
# with when('+cmake'):
#     depends_on("cmake@3.14.0:", type="build")
#     conflicts('@:6.7', msg='+cmake works since QE v6.8')

# EPW has conflicts with 64-bit indicies in older versions of QE?
# ==> Error: ProcessError: Command exited with status 2:
#    'make' 'all' 'epw'
#
#55 errors found in build log:
#     1237    
#     1238     2405 |    CALL MPI_Sendrecv_replace( buf, SIZE(buf), MPI_DOUBLE_P
#             RECISION, &
#     1239          |                              1
#     1240    ......
#     1241     2439 |    CALL MPI_Sendrecv_replace( buf, SIZE(buf), MPI_DOUBLE_C
#             OMPLEX, &
#     1242          |                              2
#  >> 1243    Error: Type mismatch between actual argument at (1) and actual arg
#             ument at (2) (REAL(8)/COMPLEX(8)).
#     1244    mp.f90:2370:30:
#     1245    
#     1246     2370 |    CALL MPI_Sendrecv_replace( buf, SIZE(buf), MPI_INTEGER,
#              &
#     1247          |                              1
#     1248    ......
#     1249     2439 |    CALL MPI_Sendrecv_replace( buf, SIZE(buf), MPI_DOUBLE_C
#             OMPLEX, &
#     1250          |                              2
#  >> 1251    Error: Type mismatch between actual argument at (1) and actual arg
#             ument at (2) (INTEGER(4)/COMPLEX(8)).
#     1252    mp.f90:2335:30:

declare -xr SPACK_PACKAGE='quantum-espresso@6.4.1'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~cmake ~elpa +environ ~epw ~ipo +mpi ~openmp +patch ~qmcpack +scalapack'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.18/$(spack find --format '{hash:7}' openblas@0.3.18 % ${SPACK_COMPILER} ~ilp64 threads=none) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^netlib-scalapack@2.1.0/$(spack find --format '{hash:7}' netlib-scalapack@2.1.0 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'paraview@5.9.1.sh'

sleep 60
