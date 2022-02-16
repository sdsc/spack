#!/usr/bin/env bash
# real 239.97

#SBATCH --job-name=gdb@9.2
#SBATCH --account=use300
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.1'
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

# ==> Error: gdb@9.2%gcc@10.2.0~gold~ld~lto+python~quad~source-highlight~tui+xz ^bzip2@1.0.8%gcc@10.2.0~debug~pic+shared arch=linux-centos8-zen2 ^expat@2.4.1%gcc@10.2.0+libbsd arch=linux-centos8-zen2 ^gdbm@1.21%gcc@10.2.0 arch=linux-centos8-zen2 ^gettext@0.21%gcc@10.2.0+bzip2+curses+git~libunistring~libxml2+tar+xz arch=linux-centos8-zen2 ^libbsd@0.11.3%gcc@10.2.0 arch=linux-centos8-zen2 ^libffi@3.3%gcc@10.2.0 patches=26f26c6f29a7ce9bf370ad3ab2610f99365b4bdd7b82e7c31df41a3370d685c0 arch=linux-centos8-zen2 ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-centos8-zen2 ^libmd@1.0.3%gcc@10.2.0 arch=linux-centos8-zen2 ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-centos8-zen2 ^openssl@1.1.1c%gcc@10.2.0~docs certs=system arch=linux-centos8-zen2 ^python@3.8.5%gcc@10.2.0+bz2+ctypes+dbm~debug~libxml2+lzma~nis+optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tix~tkinter~ucs4+uuid+zlib patches=0d98e93189bc278fbc37a50ed7f183bd8aaf249a8e1670a465f0db6bb4f8cf87,4c2457325f2b608b1b6a2c63087df8c26e07db3e3d493caf36a56f0ecf6fb768,f2fd060afc4b4618fe8104c4c5d771f36dc55b1db5a4623785a4ea707ec72fb4 arch=linux-centos8-zen2 ^readline@8.1%gcc@10.2.0 arch=linux-centos8-zen2 ^sqlite@3.33.0%gcc@10.2.0+column_metadata+fts+functions+rtree arch=linux-centos8-zen2 ^tar@1.34%gcc@10.2.0 arch=linux-centos8-zen2 ^util-linux-uuid@2.36.2%gcc@10.2.0 arch=linux-centos8-zen2 ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-centos8-zen2 ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-centos8-zen2 is unsatisfiable, errors are:
#
#    To see full clingo unsat cores, re-run with `spack --show-cores=full`
#    For full, subset-minimal unsat cores, re-run with `spack --show-cores=minimized
#    Warning: This may take (up to) hours for some specs
declare -xr SPACK_PACKAGE='gdb@9.2'
declare -xr SPACK_COMPILER='gcc@10.2.0'
#declare -xr SPACK_VARIANTS='~gold ~ld ~lto +python ~quad ~source-highlight ~tui +xz'
#declare -xr SPACK_DEPENDENCIES="^python@3.8.5/$(spack find --format '{hash:7}' python@3.8.5 % ${SPACK_COMPILER})"
declare -xr SPACK_VARIANTS='~gold ~ld ~lto ~python ~quad ~source-highlight ~tui +xz'
declare -xr SPACK_DEPENDENCIES=''
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'ninja@1.10.1.sh'

sleep 60
