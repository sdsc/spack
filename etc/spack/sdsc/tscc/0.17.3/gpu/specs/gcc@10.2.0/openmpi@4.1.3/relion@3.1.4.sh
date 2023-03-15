#!/usr/bin/env bash

#SBATCH --job-name=relion@3.1.4
#SBATCH --account=sdsc
#SBATCH --partition=hotel
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

# Note: This problem only occured with the latest version of the 
# package.py file when libpng is required. Issue will need to be sorted
# out in the future, if libpng is important for relion long-term.
#
# ==> Installing gdk-pixbuf-2.42.2-zcyz4j5hnxenlkhbywsjgpdlt5naf4yv
# ==> No binary for gdk-pixbuf-2.42.2-zcyz4j5hnxenlkhbywsjgpdlt5naf4yv found: installing from source
# ==> Fetching https://mirror.spack.io/_source-cache/archive/83/83c66a1cfd591d7680c144d2922c5955d38b4db336d7cd3ee109f7bcf9afef15.tar.xz
# ==> No patches needed for gdk-pixbuf
# ==> gdk-pixbuf: Executing phase: 'install'
# ==> Error: ProcessError: Command exited with status 1:
#    'meson' '..' '--prefix=/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/gdk-pixbuf-2.42.2-zcyz4j5hnxenlkhbywsjgpdlt5naf4yv' '--libdir=/home/mkandes/cm/shared/apps/spack/0.17.3/gpu/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/gdk-pixbuf-2.42.2-zcyz4j5hnxenlkhbywsjgpdlt5naf4yv/lib' '-Dbuildtype=release' '-Dstrip=false' '-Ddefault_library=shared' '-Dx11=False' '-Dman=False'
#
# 1 error found in build log:
#     3    The Meson build system
#     4    Version: 0.60.0
#     5    Source dir: /tmp/mkandes/spack-stage/spack-stage-gdk-pixbuf-2.42.2-zc
#          yz4j5hnxenlkhbywsjgpdlt5naf4yv/spack-src
#     6    Build dir: /tmp/mkandes/spack-stage/spack-stage-gdk-pixbuf-2.42.2-zcy
#          z4j5hnxenlkhbywsjgpdlt5naf4yv/spack-src/spack-build
#     7    Build type: native build
#     8    
#  >> 9    ../meson.build:1:0: ERROR: Unknown options: "x11"
#     10   
#     11   A full log can be found at /tmp/mkandes/spack-stage/spack-stage-gdk-p
#          ixbuf-2.42.2-zcyz4j5hnxenlkhbywsjgpdlt5naf4yv/spack-src/spack-build/m
#          eson-logs/meson-log.txt
#
# See build log for details:
#  /tmp/mkandes/spack-stage/spack-stage-gdk-pixbuf-2.42.2-zcyz4j5hnxenlkhbywsjgpdlt5naf4yv/spack-build-out.txt

declare -xr SPACK_PACKAGE='relion@3.1.4'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+allow_ctf_in_sagd +cuda cuda_arch=70,80 +double ~double-gpu ~gui ~ipo ~mklfft'
declare -xr SPACK_DEPENDENCIES="^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} +mpi ~openmp ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types relion@3.1.4 % gcc@10.2.0 +allow_ctf_in_sagd +cuda cuda_arch=70,80 +double ~double-gpu ~gui ~ipo ~mklfft "^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} +mpi ~openmp ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all relion@3.1.4 % gcc@10.2.0 +allow_ctf_in_sagd +cuda cuda_arch=70,80 +double ~double-gpu ~gui ~ipo ~mklfft "^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} +mpi ~openmp ^openmpi@4.1.3)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
