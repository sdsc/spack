#!/usr/bin/env bash
# real 290.12

#SBATCH --job-name=lammps@20200721
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

#==> Error: Detected uninstalled dependencies for python: {'gettext'}
#==> Error: Cannot proceed with python: 1 uninstalled dependency: gettext
#ERROR: spack install failed.

declare -xr SPACK_PACKAGE='lammps@20200721'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+asphere +body +class2 +colloid +compress +coreshell ~cuda +dipole +exceptions +ffmpeg +granular +jpeg +kim +kokkos +kspace +latte +lib +manybody +mc ~meam +misc +mliap +molecule +mpi +mpiio ~opencl +openmp +opt +peri +png +poems ~python +qeq +replica +rigid +shock +snap +spin +srd ~user-adios +user-atc +user-awpmd +user-bocs +user-cgsdk +user-colvars +user-diffraction +user-dpd +user-drude +user-eff +user-fep ~user-h5md +user-lb +user-manifold +user-meamc +user-mesodpd +user-mesont +user-mgpt +user-misc +user-mofff ~user-netcdf ~user-omp +user-phonon ~user-plumed +user-ptm +user-qtb +user-reaction +user-reaxc +user-sdpd +user-smd +user-sph +user-tally +user-uef +user-yaff +voronoi'
declare -xr SPACK_DEPENDENCIES="^openblas@0.3.10/$(spack find --format '{hash:7}' openblas@0.3.10 % ${SPACK_COMPILER} +ilp64 threads=none) ^fftw@3.3.8/$(spack find --format '{hash:7}' fftw@3.3.8 % ${SPACK_COMPILER} +mpi ^openmpi@4.0.5) ^kokkos@3.1.01/$(spack find --format '{hash:7}' kokkos@3.1.01 % ${SPACK_COMPILER})"
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
