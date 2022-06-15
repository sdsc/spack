#!/usr/bin/env bash

#SBATCH --job-name=openmpi@4.1.3
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

declare -xr SPACK_VERSION='0.17.2'
declare -xr SPACK_INSTANCE_NAME='cpu'
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

# when attempting to build all dependencies natively with aocc@3.2.0; must build some dependencies with gcc as outlined in AMD instructions; see https://developer.amd.com/spack/hpc-applications-openmpi/ 
#
# ==> Installing ucx-1.10.1-3dp52porla3vtarg5ez75ukfl7i7d23s
# ==> No binary for ucx-1.10.1-3dp52porla3vtarg5ez75ukfl7i7d23s found: installing from source
# ==> Using cached archive: /home/mkandes/cm/shared/apps/spack/0.17.2/cpu/var/spack/cache/_source-cache/archive/ae/ae9a108af6842ca135e7ec9b6131469adf9f1e50f899349fafcc69a215368bc9.tar.gz
# ==> No patches needed for ucx
# ==> ucx: Executing phase: 'autoreconf'
# ==> ucx: Executing phase: 'configure'
# ==> Error: ProcessError: Command exited with status 127:
#    'contrib/configure-release' '--prefix=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen2/aocc-3.2.0/ucx-1.10.1-3dp52porla3vtarg5ez75ukfl7i7d23s' '--enable-mt' '--disable-cma' '--disable-params-check' '--with-avx' '--enable-optimizations' '--disable-assertions' '--disable-logging' '--with-pic' '--without-rc' '--without-ud' '--without-dc' '--without-mlx5-dv' '--without-ib-hw-tm' '--without-dm' '--without-cm' '--without-rocm' '--without-java' '--without-cuda' '--without-gdrcopy' '--without-knem' '--without-xpmem' 'LDFLAGS=-fuse-ld=bfd'
#
# 1 error found in build log:
#     287    checking whether bfd_get_section_flags is declared... no
#     288    checking whether bfd_section_flags is declared... no
#     289    checking whether bfd_get_section_vma is declared... no
#     290    checking whether bfd_section_vma is declared... no
#     291    checking bfd_section_size API version... 2-args API
#     292    configure: WARNING: detailed backtrace is not supported
#  >> 293    checking __attribute__((constructor))... configure: error: Cannot c
#            ontinue. Please use compiler that
#     294                                 supports __attribute__((constructor))
#
#See build log for details:
#  /tmp/mkandes/spack-stage/spack-stage-ucx-1.10.1-3dp52porla3vtarg5ez75ukfl7i7d23s/spack-build-out.txt
#
#==> Warning: Skipping build of openmpi-4.1.3-ikwulb2tnxsgpfl5sf7rutwgk7dpulak since ucx-1.10.1-3dp52porla3vtarg5ez75ukfl7i7d23s failed
#==> Error: Terminating after first install failure: ProcessError: Command exited with status 127:
#    'contrib/configure-release' '--prefix=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen2/aocc-3.2.0/ucx-1.10.1-3dp52porla3vtarg5ez75ukfl7i7d23s' '--enable-mt' '--disable-cma' '--disable-params-check' '--with-avx' '--enable-optimizations' '--disable-assertions' '--disable-logging' '--with-pic' '--without-rc' '--without-ud' '--without-dc' '--without-mlx5-dv' '--without-ib-hw-tm' '--without-dm' '--without-cm' '--without-rocm' '--without-java' '--without-cuda' '--without-gdrcopy' '--without-knem' '--without-xpmem' 'LDFLAGS=-fuse-ld=bfd'

declare -xr SPACK_PACKAGE='openmpi@4.1.3'
declare -xr SPACK_COMPILER='aocc@3.2.0'
declare -xr SPACK_VARIANTS='~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=ucx,xpmem,knem,hcoll schedulers=slurm'
declare -xr SPACK_DEPENDENCIES="^lustre@2.12.8 ^slurm@21.08.8 ^ucx@1.10.1/$(spack find --format '{hash:7}' ucx@1.10.1 % gcc@8.5.0)"
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
spack spec --long --namespaces --types openmpi@4.1.3 % aocc@3.2.0 ~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=ucx schedulers=slurm ^lustre@2.12.8 ^slurm@21.08.8 "^ucx@1.10.1/$(spack find --format '{hash:7}' ucx@1.10.1 % gcc@8.5.0)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all openmpi@4.1.3 % aocc@3.2.0 ~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix+romio~rsh~singularity+static+vt+wrapper-rpath cuda_arch=none fabrics=ucx schedulers=slurm ^lustre@2.12.8 ^slurm@21.08.8 "^ucx@1.10.1/$(spack find --format '{hash:7}' ucx@1.10.1 % gcc@8.5.0)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sleep 60
