#!/usr/bin/env bash

#SBATCH --job-name=ucx@1.10.1
#SBATCH --account=use300
#SBATCH --clusters=expanse
#SBATCH --partition=ind-gpu-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=92G
#SBATCH --gpus=1
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xir UNIX_TIME="$(date +'%s')"
declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"

declare -xr LOCAL_SCRATCH_DIR="/scratch/${USER}/job_${SLURM_JOB_ID}"

declare -xr JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr JOB_SCRIPT_MD5="$(md5sum ${JOB_SCRIPT} | awk '{print $1}')"
declare -xr JOB_SCRIPT_SHA256="$(sha256sum ${JOB_SCRIPT} | awk '{print $1}')"
declare -xr JOB_SCRIPT_NUMBER_OF_LINES="$(wc -l ${JOB_SCRIPT} | awk '{print $1}')"

declare -xr SCHEDULER_NAME='slurm'
declare -xr SCHEDULER_MAJOR='23'
declare -xr SCHEDULER_MINOR='02'
declare -xr SCHEDULER_REVISION='7'
declare -xr SCHEDULER_VERSION="${SCHEDULER_MAJOR}.${SCHEDULER_MINOR}.${SCHEDULER_REVISION}"
declare -xr SCHEDULER_MODULE="${SCHEDULER_NAME}/${SLURM_CLUSTER_NAME}/${SCHEDULER_VERSION}"

declare -xr SPACK_MAJOR='0'
declare -xr SPACK_MINOR='17'
declare -xr SPACK_REVISION='3'
declare -xr SPACK_VERSION="${SPACK_MAJOR}.${SPACK_MINOR}.${SPACK_REVISION}"
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_VERSION='dev'
declare -xr SPACK_INSTANCE_DIR='/home/mkandes/software/spack/repos/mkandes/spack'

declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}/spack-stage"
declare -xr TMP="${TMPDIR}"

echo "${UNIX_TIME} ${LOCAL_TIME} ${SLURM_JOB_ID} ${JOB_SCRIPT_MD5} ${JOB_SCRIPT_SHA256} ${JOB_SCRIPT_NUMBER_OF_LINES} ${JOB_SCRIPT}"
cat  "${JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

#==> Installing ucx-1.10.1-hqmeaineuq6aq4ptuvd5kpbw7o3wb46q
#==> No binary for ucx-1.10.1-hqmeaineuq6aq4ptuvd5kpbw7o3wb46q found: installing from source
#==> Warning: Expected user 501506 to own /scratch/mkandes, but it is owned by 0
#==> Using cached archive: /home/mkandes/software/spack/repos/mkandes/spack/var/spack/cache/_source-cache/archive/ae/ae9a108af6842ca135e7ec9b6131469adf9f1e50f899349fafcc69a215368bc9.tar.gz
#==> No patches needed for ucx
#==> ucx: Executing phase: 'autoreconf'
#==> ucx: Executing phase: 'configure'
#==> Error: ProcessError: Command exited with status 1:
#    'contrib/configure-release' '--prefix=/home/mkandes/software/spack/repos/mkandes/spack/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/ucx-1.10.1-hqmeaineuq6aq4ptuvd5kpbw7o3wb46q' '--enable-mt' '--enable-cma' '--disable-params-check' '--with-avx' '--enable-optimizations' '--disable-assertions' '--disable-logging' '--with-pic' '--with-rc' '--with-ud' '--with-dc' '--with-mlx5-dv' '--with-ib-hw-tm' '--with-dm' '--with-cm' '--without-rocm' '--without-java' '--with-cuda=/home/mkandes/software/spack/repos/mkandes/spack/opt/spack/linux-rocky8-cascadelake/gcc-10.2.0/cuda-11.2.2-nymvp54yiooltc5wzqhb2unwjiwkwcmu' '--with-gdrcopy=/usr' '--with-knem=/opt/knem-1.1.4.90mlnx3' '--with-xpmem=/usr'
#
#1 error found in build log:
#     411    checking for struct ibv_tm_caps.flags... yes
#     412    checking whether ibv_exp_alloc_dm is declared... no
#     413    checking whether ibv_alloc_dm is declared... yes
#     414    checking whether ibv_cmd_modify_qp is declared... no
#     415    configure: Checking OFED valgrind libs /usr/lib64/mlnx_ofed/valgrin
#            d
#     416    checking for ib_cm_send_req in -libcm... no
#  >> 417    configure: error: CM requested but lib ibcm not found
#
#See build log for details:
#  /scratch/mkandes/job_33766496/spack-stage/spack-stage/spack-stage-ucx-1.10.1-hqmeaineuq6aq4ptuvd5kpbw7o3wb46q/spack-build-out.txt

declare -xr SPACK_PACKAGE='ucx@1.10.1'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~assertions ~cm +cma +cuda cuda_arch=70,80 +dc ~debug +dm +gdrcopy +ib-hw-tm ~java +knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud +xpmem'
eclare -xr SPACK_DEPENDENCIES="^cuda@11.2.2/$(spack find --format '{hash:7}' cuda@11.2.2 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS}" #${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types --reuse ucx@1.10.1 % "${SPACK_COMPILER}" ~assertions ~cm +cma +cuda cuda_arch='70,80' +dc ~debug +dm +gdrcopy +ib-hw-tm ~java +knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud +xpmem "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

mkdir -p "${TMPDIR}"

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all --reuse ucx@1.10.1 % "${SPACK_COMPILER}" ~assertions ~cm +cma +cuda cuda_arch='70,80' +dc ~debug +dm +gdrcopy +ib-hw-tm ~java +knem ~logging +mlx5-dv +optimizations ~parameter_checking +pic +rc ~rocm +thread_multiple +ud +xpmem "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi
