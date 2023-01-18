#!/usr/bin/env bash

#SBATCH --job-name=ucx@1.10.1
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

declare -xr SPACK_VERSION='0.17.2'
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_DIR="${HOME}/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

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


# Note from AMD: +cm option may not work with RHEL 8 and later. 
# https://developer.amd.com/spack/hpc-applications-openmpi/

declare -xr INTEL_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='ucx@1.10.1'
declare -xr SPACK_COMPILER='intel@19.1.3.304'
declare -xr SPACK_VARIANTS='~assertions ~cm +cma +cuda cuda_arch=70,80 +dc ~debug +dm +gdrcopy +ib-hw-tm ~java ~knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud ~xpmem'
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

spack spec --long --namespaces --types ucx@1.10.1 % intel@19.1.3.304 ~assertions ~cm +cma +cuda cuda_arch=70,80 +dc ~debug +dm +gdrcopy +ib-hw-tm ~java ~knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud ~xpmem "^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all ucx@1.10.1 % intel@19.1.3.304 ~assertions ~cm +cma +cuda cuda_arch=70,80 +dc ~debug +dm +gdrcopy +ib-hw-tm ~java ~knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud ~xpmem "^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'openmpi@4.1.3.sh'

sleep 60
