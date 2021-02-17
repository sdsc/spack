#!/usr/bin/env bash

#SBATCH --job-name=anaconda3@2019.10
#SBATCH --account=use300
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128
#SBATCH --mem=248G
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.15.4'
declare -xr SPACK_INSTANCE_NAME='cpu'
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

declare -xr SPACK_PACKAGE='anaconda3@2019.10'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+X +external-lapack ~rmath'
# Problem with +rmath variantl; try again in the future
# >> 2964    cp: cannot create regular file '/home/mkandes/cm/shared/apps/spack
#             /0.15.4/cpu/opt/spack/linux-centos8-zen2/gcc-10.2.0/r-4.0.2-ei3a3l
#             o4hrd5vrk2n4u55jmrmxi23hbt/include/Rmath.h': No such file or direc
#             tory
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} threads=none) ^python@3.8.5/$(spack find --format '{hash:7}' python@3.8.5 % ${SPACK_COMPILER})"
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
spack spec --yaml "${SPACK_SPEC}"

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}"

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'anaconda3@2019.10-complex.sh'
