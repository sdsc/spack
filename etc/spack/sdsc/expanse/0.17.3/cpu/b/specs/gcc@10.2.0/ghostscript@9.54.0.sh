#!/usr/bin/env bash
# real 424.07

#SBATCH --job-name=ghostscript@9.54.0
#SBATCH --reservation=rocky8u7_testing
#SBATCH --account=use300
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=242G
#SBATCH --time=04:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"
declare -xr LOCAL_SCRATCH_DIR="/scratch/${USER}/job_${SLURM_JOB_ID}"
declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}"


declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_VERSION='b'
declare -xr SPACK_INSTANCE_NAME='cpu'
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


# [mkandes@login01 ~]$ spack --show-cores=minimized spec -l ghostscript@9.54.0 % gcc@10.2.0 ~tesseract "^meson@0.60.0/$(spack find --format '{hash:7}' meson@0.60.0 % ${SPACK_COMPILER})"
#Input spec
#--------------------------------
#ghostscript@9.54.0%gcc@10.2.0~tesseract
#    ^meson@0.60.0%gcc@10.2.0 patches=aa6c50d5a2aeb1a487d16f6712be4357fefb923aae37ab830699b07338388287 arch=linux-rocky8-zen2
#        ^ninja@1.10.2%gcc@10.2.0 arch=linux-rocky8-zen2
#        ^py-setuptools@58.2.0%gcc@10.2.0 arch=linux-rocky8-zen2
#            ^python@3.8.12%gcc@10.2.0+bz2+ctypes+dbm~debug+libxml2+lzma~nis+optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tix~tkinter~ucs4+uuid+zlib patches=0d98e93189bc278fbc37a50ed7f183bd8aaf249a8e1670a465f0db6bb4f8cf87,4c2457325f2b608b1b6a2c63087df8c26e07db3e3d493caf36a56f0ecf6fb768,f2fd060afc4b4618fe8104c4c5d771f36dc55b1db5a4623785a4ea707ec72fb4 arch=linux-rocky8-zen2
#                ^bzip2@1.0.8%gcc@10.2.0~debug~pic+shared arch=linux-rocky8-zen2
#                ^expat@2.4.1%gcc@10.2.0+libbsd arch=linux-rocky8-zen2
#                    ^libbsd@0.11.3%gcc@10.2.0 arch=linux-rocky8-zen2
#                        ^libmd@1.0.3%gcc@10.2.0 arch=linux-rocky8-zen2
#                ^gdbm@1.21%gcc@10.2.0 arch=linux-rocky8-zen2
#                    ^readline@8.1%gcc@10.2.0 arch=linux-rocky8-zen2
#                        ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-rocky8-zen2
#                ^gettext@0.21%gcc@10.2.0+bzip2+curses+git~libunistring+libxml2+tar+xz arch=linux-rocky8-zen2
#                    ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-rocky8-zen2
#                    ^libxml2@2.9.12%gcc@10.2.0~python arch=linux-rocky8-zen2
#                        ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-rocky8-zen2
#                        ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-rocky8-zen2
#                    ^tar@1.34%gcc@10.2.0 arch=linux-rocky8-zen2
#                ^libffi@3.3%gcc@10.2.0 patches=26f26c6f29a7ce9bf370ad3ab2610f99365b4bdd7b82e7c31df41a3370d685c0 arch=linux-rocky8-zen2
#                ^openssl@1.1.1k%gcc@10.2.0~docs certs=system arch=linux-rocky8-zen2
#                ^sqlite@3.36.0%gcc@10.2.0+column_metadata+fts+functions+rtree arch=linux-rocky8-zen2
#                ^util-linux-uuid@2.36.2%gcc@10.2.0 arch=linux-rocky8-zen2
#
#Concretized
#--------------------------------
#==> Error: ghostscript@9.54.0%gcc@10.2.0~tesseract ^bzip2@1.0.8%gcc@10.2.0~debug~pic+shared arch=linux-rocky8-zen2 ^expat@2.4.1%gcc@10.2.0+libbsd arch=linux-rocky8-zen2 ^gdbm@1.21%gcc@10.2.0 arch=linux-rocky8-zen2 ^gettext@0.21%gcc@10.2.0+bzip2+curses+git~libunistring+libxml2+tar+xz arch=linux-rocky8-zen2 ^libbsd@0.11.3%gcc@10.2.0 arch=linux-rocky8-zen2 ^libffi@3.3%gcc@10.2.0 patches=26f26c6f29a7ce9bf370ad3ab2610f99365b4bdd7b82e7c31df41a3370d685c0 arch=linux-rocky8-zen2 ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-rocky8-zen2 ^libmd@1.0.3%gcc@10.2.0 arch=linux-rocky8-zen2 ^libxml2@2.9.12%gcc@10.2.0~python arch=linux-rocky8-zen2 ^meson@0.60.0%gcc@10.2.0 patches=aa6c50d5a2aeb1a487d16f6712be4357fefb923aae37ab830699b07338388287 arch=linux-rocky8-zen2 ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-rocky8-zen2 ^ninja@1.10.2%gcc@10.2.0 arch=linux-rocky8-zen2 ^openssl@1.1.1k%gcc@10.2.0~docs certs=system arch=linux-rocky8-zen2 ^py-setuptools@58.2.0%gcc@10.2.0 arch=linux-rocky8-zen2 ^python@3.8.12%gcc@10.2.0+bz2+ctypes+dbm~debug+libxml2+lzma~nis+optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tix~tkinter~ucs4+uuid+zlib patches=0d98e93189bc278fbc37a50ed7f183bd8aaf249a8e1670a465f0db6bb4f8cf87,4c2457325f2b608b1b6a2c63087df8c26e07db3e3d493caf36a56f0ecf6fb768,f2fd060afc4b4618fe8104c4c5d771f36dc55b1db5a4623785a4ea707ec72fb4 arch=linux-rocky8-zen2 ^readline@8.1%gcc@10.2.0 arch=linux-rocky8-zen2 ^sqlite@3.36.0%gcc@10.2.0+column_metadata+fts+functions+rtree arch=linux-rocky8-zen2 ^tar@1.34%gcc@10.2.0 arch=linux-rocky8-zen2 ^util-linux-uuid@2.36.2%gcc@10.2.0 arch=linux-rocky8-zen2 ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-rocky8-zen2 ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-rocky8-zen2 is unsatisfiable, conflicts are:
#  condition(1912)
#  condition(1989)
#  condition(3092)
#  condition(782)
#  dependency_condition(1912,"libx11","perl")
#  dependency_condition(1989,"libxext","libx11")
#  dependency_condition(3092,"perl","gdbm")
#  dependency_condition(782,"ghostscript","libxext")
#  dependency_type(1912,"build")
#  dependency_type(1989,"link")
#  dependency_type(3092,"link")
#  dependency_type(782,"link")
#  hash("meson","bgypf75vduvrnj5qq5rcujv2xx3o4af2")
#  imposed_constraint("bgypf75vduvrnj5qq5rcujv2xx3o4af2","hash","gdbm","yi43quzh5tyjiuhijeayoug4huok4t43")
#  imposed_constraint("yi43quzh5tyjiuhijeayoug4huok4t43","version","gdbm","1.21")
#  imposed_constraint(3092,"version_satisfies","gdbm",":1.19")
#  no version satisfies the given constraints
#  root("ghostscript")
#
#[mkandes@login01 ~]$

# build still faling on rust dependency in librsvg library
# >> 10774    error: failed to run custom build command for `openssl-sys v0.9.5.8`

# librsvg added as a dependency to gtkplus here ... not entirely clear why.
# https://github.com/spack/spack/commit/43f4d2da9997a17e4c523078a0b0335350dd739a

# not the only people unhappy librsvg now depends on rust ...
# https://bugs.gentoo.org/788016
declare -xr SPACK_PACKAGE='ghostscript@9.54.0'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~tesseract'
declare -xr SPACK_DEPENDENCIES="^meson@0.60.0/$(spack find --format '{hash:7}' meson@0.60.0 % ${SPACK_COMPILER}) ^librsvg@2.42.7"
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

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --yes-to-all "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'imagemagick@7.0.8-7.sh'

sleep 30
