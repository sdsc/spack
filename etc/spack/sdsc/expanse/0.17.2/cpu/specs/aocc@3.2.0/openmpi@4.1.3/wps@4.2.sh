#!/usr/bin/env bash

#SBATCH --job-name=wps@4.2
#SBATCH --account=use300
#SBATCH --reservation=root_73
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:00:00
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

# does not compile with aocc
# ==> Ran patch() for wps
# ==> wps: Executing phase: 'configure'
# ==> Error: InstallError: Compiler not recognized nor supported.
#
# /home/mkandes/cm/shared/apps/spack/0.17.2/cpu/var/spack/repos/builtin/packages/wps/package.py:88, in configure:
#         85        try:
#         86            compiler_opts = build_opts[self.spec.compiler.name]
#         87        except KeyError:
#  >>     88            raise InstallError("Compiler not recognized nor supported.")
#         89
#         90        # Spack already makes sure that the variant value is part of the set.
#         91        build_type = compiler_opts[spec.variants['build_type'].value]
#
# See build log for details:
#   /tmp/mkandes/spack-stage/spack-stage-wps-4.2-yr5pezwpshrduvjdwl4h35bjw6rfdc74/spack-build-out.txt
#
# ==> Error: Terminating after first install failure: InstallError: Compiler not recognized nor supported.

declare -xr SPACK_PACKAGE='wps@4.2'
declare -xr SPACK_COMPILER='aocc@3.2.0'
declare -xr SPACK_VARIANTS='build_type=dmpar'
declare -xr SPACK_DEPENDENCIES="^wrf@4.2/$(spack find --format '{hash:7}' wrf@4.2 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --type wps@4.2 % aocc@3.2.0 build_type='dmpar' "^wrf@4.2/$(spack find --format '{hash:7}' wrf@4.2 % ${SPACK_COMPILER} ^openmpi@4.1.3)" 
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all wps@4.2 % aocc@3.2.0 build_type='dmpar' "^wrf@4.2/$(spack find --format '{hash:7}' wrf@4.2 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
