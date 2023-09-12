#!/usr/bin/env bash

#SBATCH --job-name=openmpi@3.1.6
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

#     13883    In file included from /usr/include/linux/fs.h:18,
#     13884                     from /usr/include/linux/lustre/lustre_user.h:54,
#     13885                     from /usr/include/lustre/lustreapi.h:46,
#     13886                     from ../../../../ompi/mca/fs/lustre/fs_lustre.h:
#              37,
#     13887                     from fs_lustre.c:30:
#  >> 13888    /usr/include/sys/mount.h:35:3: error: expected identifier before 
#              numeric constant
#     13889       35 |   MS_RDONLY = 1,  /* Mount read-only.  */
#     13890          |   ^~~~~~~~~
#     13891    fs_lustre.c: In function 'mca_fs_lustre_component_file_query':
#     13892    fs_lustre.c:91:55: warning: passing argument 1 of 'mca_fs_base_ge
#              t_fstype' discards 'const' qualifier from pointer target type [-W
#              discarded-qualifiers]

declare -xr SPACK_PACKAGE='openmpi@3.1.6'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~atomics~cuda+cxx+cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=verbs schedulers=slurm'
declare -xr SPACK_DEPENDENCIES='^lustre@2.15.2 ^slurm@21.08.8 ^rdma-core@43.0'
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types openmpi@3.1.6 % gcc@10.2.0 ~atomics~cuda+cxx+cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers~lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=verbs schedulers=slurm ^slurm@21.08.8 ^rdma-core@43.0
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all openmpi@3.1.6 % gcc@10.2.0 ~atomics~cuda+cxx+cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers~lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=verbs schedulers=slurm ^slurm@21.08.8 ^rdma-core@43.0
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

sleep 30
