#!/usr/bin/env bash

#SBATCH --job-name=lammps@20210310
#SBATCH --account=use300
#SBATCH --reservation=root_73
#SBATCH --partition=ind-shared
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

# A conflict was triggered
#  condition(2667)
#  condition(2883)
#  condition(2884)
#  conflict("lammps",2883,2884)
#  no version satisfies the given constraints
#  root("lammps")
#  variant_condition(2667,"lammps","meam")
#  variant_set("lammps","meam","True")
#  version_satisfies("lammps","20181212:","20210310")
#  version_satisfies("lammps","20210310")

# 2 errors found in build log:
#     51    -- Found VORO: /home/mkandes/cm/shared/apps/spack/0.17.2/cpu/opt/spa
#           ck/linux-rocky8-zen2/aocc-3.2.0/voropp-0.4.6-uixlmxsq5gs3ytzev6buvjt
#           ox4iq5ljp/lib/libvoro++.a
#     52    -- Checking for module 'libzstd>=1.4'
#     53    --   Found libzstd, version 1.4.4
#     54    -- Looking for C++ include cmath
#     55    -- Looking for C++ include cmath - found
#     56    -- Checking external potential C_10_10.mesocnt from https://download
#           .lammps.org/potentials
#  >> 57    CMake Error at Modules/LAMMPSUtils.cmake:101 (file):
#     58      file DOWNLOAD HASH mismatch
#     59    
#     60        for file: [/tmp/mkandes/spack-stage/spack-stage-lammps-20210310-
#           5rzvxc5q6n7mglaztrg2egdllbh5hcva/spack-build-5rzvxc5/C_10_10.mesocnt
#           ]
#     61          expected hash: [028de73ec828b7830d762702eda571c1]
#     62            actual hash: [d41d8cd98f00b204e9800998ecf8427e]
#     63                 status: [1;"Unsupported protocol"]
#     64    
#     65    Call Stack (most recent call first):
#     66      CMakeLists.txt:428 (FetchPotentials)
#     67    
#     68    
#     69    -- Checking external potential TABTP_10_10.mesont from https://downl
#           oad.lammps.org/potentials
#  >> 70    CMake Error at Modules/LAMMPSUtils.cmake:101 (file):
#     71      file DOWNLOAD HASH mismatch
#     72    
#     73        for file: [/tmp/mkandes/spack-stage/spack-stage-lammps-20210310-
#           5rzvxc5q6n7mglaztrg2egdllbh5hcva/spack-build-5rzvxc5/TABTP_10_10.mes
#           ont]
#     74          expected hash: [744a739da49ad5e78492c1fc9fd9f8c1]
#     75            actual hash: [d41d8cd98f00b204e9800998ecf8427e]
#     76                 status: [1;"Unsupported protocol"]

declare -xr SPACK_PACKAGE='lammps@20210310'
declare -xr SPACK_COMPILER='aocc@3.2.0'
#declare -xr SPACK_VARIANTS='+asphere +body +class2 +colloid +compress +coreshell ~cuda +dipole ~exceptions ~ffmpeg +granular ~ipo +jpeg ~kim ~kokkos +kspace ~latte +lib +manybody +mc ~meam +misc +mliap +molecule +mpi +mpiio ~opencl +openmp +opt +peri +png +poems ~python +qeq +replica +rigid +shock +snap +spin +srd ~user-adios +user-atc +user-awpmd +user-bocs +user-cgsdk +user-colvars +user-diffraction +user-dpd +user-drude +user-eff +user-fep ~user-h5md +user-lb +user-manifold +user-meamc +user-mesodpd +user-mesont +user-mgpt +user-misc +user-mofff ~user-netcdf ~user-omp +user-phonon ~user-plumed +user-ptm +user-qtb +user-reaction +user-reaxc +user-sdpd +user-smd +user-smtbq +user-sph +user-tally +user-uef +user-yaff +voronoi'
declare -xr SPACK_VARIANTS='~kim +asphere +class2 +kspace +manybody +molecule +mpiio +opt +replica +rigid +granular +openmp'
declare -xr SPACK_DEPENDENCIES="^amdblis@3.1/$(spack find --format '{hash:7}' amdblis@3.1 % ${SPACK_COMPILER} ~ilp64 threads=none) ^amdlibflame@3.1/$(spack find --format '{hash:7}' amdlibflame@3.1 % ${SPACK_COMPILER} ~ilp64 ^amdblis@3.1 threads=none) ^amdfftw@3.1/$(spack find --format '{hash:7}' amdfftw@3.1 % ${SPACK_COMPILER} ~mpi ~openmp) ^openmpi@4.1.3/$(spack find --format '{hash:7}' openmpi@4.1.3 % ${SPACK_COMPILER})"
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

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'nwchem@7.0.2.sh'

sleep 60
