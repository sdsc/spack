#!/usr/bin/env bash

#SBATCH --job-name=ucx@1.10.1
#SBATCH --account=use300
#SBATCH --partition=shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=01:00:00
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

# Note from AMD: +cm option may not work with RHEL 8 and later. 
# https://developer.amd.com/spack/hpc-applications-openmpi/
#
# ==> Installing ucx-1.10.1-p3zsepkh3zwlw2mdsc3zajgxfgoqblho
# ==> No binary for ucx-1.10.1-p3zsepkh3zwlw2mdsc3zajgxfgoqblho found: installing from source
# ==> Using cached archive: /home/mkandes/cm/shared/apps/spack/0.17.2/cpu/var/spack/cache/_source-cache/archive/ae/ae9a108af6842ca135e7ec9b6131469adf9f1e50f899349fafcc
# 69a215368bc9.tar.gz
# ==> No patches needed for ucx
# ==> ucx: Executing phase: 'autoreconf'
# ==> ucx: Executing phase: 'configure'
# ==> Error: ProcessError: Command exited with status 1:
#    'contrib/configure-release' '--prefix=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/ucx-1.10.1-p3zsepkh3zwlw2mdsc3zajgxfgoqb
# lho' '--enable-mt' '--enable-cma' '--disable-params-check' '--with-avx' '--enable-optimizations' '--disable-assertions' '--disable-logging' '--with-pic' '--with-rc' 
# '--with-ud' '--with-dc' '--with-mlx5-dv' '--with-ib-hw-tm' '--with-dm' '--with-cm' '--without-rocm' '--without-java' '--without-cuda' '--without-gdrcopy' '--with-kne
# m=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/knem-1.1.4-dtpqb42ih64kccsdfnq75xnlxjun2zps' '--with-xpmem=/home/mkandes/cm/shar
# ed/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/xpmem-2.6.5-36-jnrkrz24hnkz4sdli7smyv5enp27t5kw'
#
#1 error found in build log:
#     399    checking for struct ibv_tm_caps.flags... yes
#     400    checking whether ibv_exp_alloc_dm is declared... no
#     401    checking whether ibv_alloc_dm is declared... yes
#     402    checking whether ibv_cmd_modify_qp is declared... no
#     403    configure: Checking OFED valgrind libs /usr/lib64/mlnx_ofed/valgrin
#            d
#     404    checking for ib_cm_send_req in -libcm... no
#  >> 405    configure: error: CM requested but lib ibcm not found
#
#See build log for details:
#  /tmp/mkandes/spack-stage/spack-stage-ucx-1.10.1-p3zsepkh3zwlw2mdsc3zajgxfgoqblho/spack-build-out.txt
#
# ==> Error: Terminating after first install failure: ProcessError: Command exited with status 1:
#    'contrib/configure-release' '--prefix=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/ucx-1.10.1-p3zsepkh3zwlw2mdsc3zajgxfgoqblho' '--enable-mt' '--enable-cma' '--disable-params-check' '--with-avx' '--enable-optimizations' '--disable-assertions' '--disable-logging' '--with-pic' '--with-rc' '--with-ud' '--with-dc' '--with-mlx5-dv' '--with-ib-hw-tm' '--with-dm' '--with-cm' '--without-rocm' '--without-java' '--without-cuda' '--without-gdrcopy' '--with-knem=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/knem-1.1.4-dtpqb42ih64kccsdfnq75xnlxjun2zps' '--with-xpmem=/home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spack/linux-rocky8-zen/gcc-8.5.0/xpmem-2.6.5-36-jnrkrz24hnkz4sdli7smyv5enp27t5kw'

declare -xr SPACK_PACKAGE='ucx@1.10.1'
declare -xr SPACK_COMPILER='gcc@8.5.0'
#declare -xr SPACK_VARIANTS='~assertions ~cm +cma ~cuda +dc ~debug +dm ~gdrcopy +ib-hw-tm ~java +knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud +xpmem'
declare -xr SPACK_VARIANTS='~assertions ~cm ~cma ~cuda ~dc ~debug ~dm ~gdrcopy ~ib-hw-tm ~java ~knem ~logging ~mlx5-dv +optimizations ~parameter_checking +pic ~rc ~rocm +thread_multiple ~ud ~xpmem'
#declare -xr SPACK_DEPENDENCIES="^xpmem@2.6.5-36/$(spack find --format '{hash:7}' xpmem@2.6.5-36 % ${SPACK_COMPILER}) ^hwloc@2.6.0 +libudev"
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

#sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 60
