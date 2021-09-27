#!/usr/bin/env bash

#SBATCH --job-name=openmpi@4.0.5
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

declare -xr SPACK_PACKAGE='openmpi@4.0.5'
declare -xr SPACK_COMPILER='gcc@8.4.0'
declare -xr SPACK_VARIANTS='~atomics +cuda ~cxx ~cxx_exceptions ~gpfs ~java +legacylaunchers +lustre ~memchecker +pmi ~singularity ~sqlite3 +static +thread_multiple +wrapper-rpath'
declare -xr SPACK_DEPENDENCIES='^hwloc@1.11.11 ^lustre@2.12.5 ^slurm@20.02.3 ^rdma-core@47 ^cuda@10.2.89'
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

echo "${SPACK_SPEC}"
# concretization fails for some reason when using SPACK_SPEC environment variable; investigate again in the future
# openmpi@4.0.5 % gcc@8.4.0 +legacylaunchers +lustre +pmi schedulers=slurm fabrics=ucx ^hwloc@1.11.11 ^lustre@2.12.5 ^slurm@20.02.3 ^rdma-core@47
# ==> Error: invalid values for variant "schedulers" in package "openmpi": ['slurm fabrics=ucx ^hwloc@1.11.11 ^lustre@2.12.5 ^slurm@20.02.3 ^rdma-core@47']
spack spec --long --namespaces --types openmpi@4.0.5 % gcc@8.4.0 ~atomics +cuda ~cxx ~cxx_exceptions ~gpfs ~java +legacylaunchers +lustre ~memchecker +pmi ~singularity ~sqlite3 +static +thread_multiple +wrapper-rpath schedulers=slurm fabrics=verbs ^hwloc@1.11.11 ^lustre@2.12.5 ^slurm@20.02.3 ^rdma-core@47 ^cuda@10.2.89
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all openmpi@4.0.5 % gcc@8.4.0 ~atomics +cuda ~cxx ~cxx_exceptions ~gpfs ~java +legacylaunchers +lustre ~memchecker +pmi ~singularity ~sqlite3 +static +thread_multiple +wrapper-rpath schedulers=slurm fabrics=verbs ^hwloc@1.11.11 ^lustre@2.12.5 ^slurm@20.02.3 ^rdma-core@47 ^cuda@10.2.89
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

cd "${SPACK_PACKAGE}"

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
