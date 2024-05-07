#!/usr/bin/env bash

#SBATCH --job-name=gcc@10.2.0
#SBATCH --account=use300
#SBATCH --clusters=expanse
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
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
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_VERSION='dev'
declare -xr SPACK_INSTANCE_DIR='/home/mkandes/software/spack/repositories/mkandes/spack'

declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}/spack-stage"
declare -xr TMP="${TMPDIR}"

declare -xr SPACK_PACKAGE='gcc@10.2.0'
declare -xr SPACK_COMPILER='gcc@8.5.0'
declare -xr SPACK_VARIANTS='~binutils ~bootstrap ~graphite ~nvptx ~piclibs ~strip'
declare -xr SPACK_DEPENDENCIES=''
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

echo "${UNIX_TIME} ${LOCAL_TIME} ${SLURM_JOB_ID} ${JOB_SCRIPT_MD5} ${JOB_SCRIPT_SHA256} ${JOB_SCRIPT_NUMBER_OF_LINES} ${JOB_SCRIPT}"
cat  "${JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"
printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

time -p spack spec --long --namespaces --types --reuse "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

mkdir -p "${TMPDIR}"

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all --reuse "$(echo ${SPACK_SPEC})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack compiler add --scope site "$(spack location -i ${SPACK_PACKAGE})"

cd "${SPACK_PACKAGE}"

CMAKE_JOB_ID="$(sbatch --dependency="afterok:${SLURM_JOB_ID}" 'cmake@3.21.4.sh' | grep -o '[[:digit:]]*')"
  EIGEN_JOB_ID="$(sbatch --dependency="afterok:${CMAKE_JOB_ID}" 'eigen@3.4.0.sh' | grep -o '[[:digit:]]*')"
  GDB_JOB_ID="$(sbatch --dependency="afterok:${CMAKE_JOB_ID}" 'gdb@11.1.sh' | grep -o '[[:digit:]]*')"
    AMDFFTW_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'amdfftw@3.1.sh' | grep -o '[[:digit:]]*')"
    AMDFFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'amdfftw@3.1-omp.sh' | grep -o '[[:digit:]]*')"
    LIBXC_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'libxc@5.1.5.sh' | grep -o '[[:digit:]]*')"
    OPENBLAS_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'openblas@0.3.18.sh' | grep -o '[[:digit:]]*')"
    OPENBLAS_I64_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'openblas@0.3.18-i64.sh' | grep -o '[[:digit:]]*')"
    OPENBLAS_OMP_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'openblas@0.3.18-omp.sh' | grep -o '[[:digit:]]*')"
    OPENBLAS_I64_OMP_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'openblas@0.3.18-i64-omp.sh' | grep -o '[[:digit:]]*')"
    SCOTCH_JOB_ID="$(sbatch --dependency="afterok:${GDB_JOB_ID}" 'scotch@6.1.1.sh' | grep -o '[[:digit:]]*')"
  HDF5_JOB_ID="$(sbatch --dependency="afterok:${CMAKE_JOB_ID}" 'hdf5@1.10.7.sh' | grep -o '[[:digit:]]*')"
    NETCDF_C_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}" 'netcdf-c@4.8.1.sh' | grep -o '[[:digit:]]*')"
      NETCDF_CXX4_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_C_JOB_ID}" 'netcdf-cxx4@4.3.1.sh' | grep -o '[[:digit:]]*')"
      NETCDF_FORTRAN_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_C_JOB_ID}" 'netcdf-fortran@4.5.3.sh' | grep -o '[[:digit:]]*')"
  METIS_JOB_ID="$(sbatch --dependency="afterok:${CMAKE_JOB_ID}" 'metis@5.1.0.sh' | grep -o '[[:digit:]]*')"
  NETLIB_LAPACK_JOB_ID="$(sbatch --dependency="afterok:${CMAKE_JOB_ID}" 'netlib-lapack@3.9.1.sh' | grep -o '[[:digit:]]*')"
  SQLITE_JOB_ID="$(sbatch --dependency="afterok:${CMAKE_JOB_ID}" 'sqlite@3.36.0.sh' | grep -o '[[:digit:]]*')"
    PYTHON_JOB_ID="$(sbatch --dependency="afterok:${SQLITE_JOB_ID}" 'python@3.8.12.sh' | grep -o '[[:digit:]]*')"
      AMDBLIS_JOB_ID="$(sbatch --dependency="afterok:${PYTHON_JOB_ID}" 'amdblis@3.1.sh' | grep -o '[[:digit:]]*')"
        AMDLIBFLAME_JOB_ID="$(sbatch --dependency="afterok:${AMDBLIS_JOB_ID}" 'amdlibflame@3.1.sh' | grep -o '[[:digit:]]*')"
      AMDBLIS_I64_JOB_ID="$(sbatch --dependency="afterok:${PYTHON_JOB_ID}" 'amdblis@3.1-i64.sh' | grep -o '[[:digit:]]*')"
        AMDLIBFLAME_I64_JOB_ID="$(sbatch --dependency="afterok:${AMDBLIS_I64_JOB_ID}" 'amdlibflame@3.1-i64.sh' | grep -o '[[:digit:]]*')"
      AMDBLIS_OMP_JOB_ID="$(sbatch --dependency="afterok:${PYTHON_JOB_ID}" 'amdblis@3.1-omp.sh' | grep -o '[[:digit:]]*')"
        AMDLIBFLAME_OMP_JOB_ID="$(sbatch --dependency="afterok:${AMDBLIS_OMP_JOB_ID}" 'amdlibflame@3.1-omp.sh' | grep -o '[[:digit:]]*')"
      AMDBLIS_I64_OMP_JOB_ID="$(sbatch --dependency="afterok:${PYTHON_JOB_ID}" 'amdblis@3.1-i64-omp.sh' | grep -o '[[:digit:]]*')"
        AMDLIBFLAME_JOB_ID="$(sbatch --dependency="afterok:${AMDBLIS_I64_OMP_JOB_ID}" 'amdlibflame@3.1-i64-omp.sh' | grep -o '[[:digit:]]*')"
      SETUPTOOLS_JOB_ID="$(sbatch --dependency="afterok:${PYTHON_JOB_ID}" 'py-setuptools@58.2.0.sh' | grep -o '[[:digit:]]*')"
        CYTHON_JOB_ID="$(sbatch --dependency="afterok:${SETUPTOOLS_JOB_ID}" 'py-cython@0.29.24.sh' | grep -o '[[:digit:]]*')"
          NUMPY_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_JOB_ID}" 'py-numpy@1.21.3.sh' | grep -o '[[:digit:]]*')"
             BOOST_JOB_ID="$(sbatch --dependency="afterok:${NUMPY_JOB_ID}" 'boost@1.77.0.sh' | grep -o '[[:digit:]]*')"
               CGAL4_JOB_ID="$(sbatch --dependency="afterok:${BOOST_JOB_ID}" 'cgal@4.13.sh' | grep -o '[[:digit:]]*')"
               CGAL5_JOB_ID="$(sbatch --dependency="afterok:${BOOST_JOB_ID}" 'cgal@5.0.3.sh' | grep -o '[[:digit:]]*')"
               IQTREE_JOB_ID="$(sbatch --dependency="afterok:${BOOST_JOB_ID}" 'iq-tree@2.1.3.sh' | grep -o '[[:digit:]]*')"
          NUMPY_I64_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_I64_JOB_ID}" 'py-numpy@1.21.3-i64.sh' | grep -o '[[:digit:]]*')"
          NUMPY_OMP_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_OMP_JOB_ID}" 'py-numpy@1.21.3-omp.sh' | grep -o '[[:digit:]]*')"
          NUMPY_I64_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_I64_OMP_JOB_ID}" 'py-numpy@1.21.3-i64-omp.sh' | grep -o '[[:digit:]]*')"
        PIP_JOB_ID="$(sbatch --dependency="afterok:${SETUPTOOLS_JOB_ID}" 'py-pip@21.1.2.sh' | grep -o '[[:digit:]]*')"
        VENV_JOB_ID="$(sbatch --dependency="afterok:${SETUPTOOLS_JOB_ID}" 'py-virtualenv@16.7.6.sh' | grep -o '[[:digit:]]*')"
FFTW_JOB_ID="$(sbatch --dependency="afterok:${SLURM_JOB_ID}" 'fftw@3.3.10.sh' | grep -o '[[:digit:]]*')"
FFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${SLURM_JOB_ID}" 'fftw@3.3.10-omp.sh' | grep -o '[[:digit:]]*')"
GSL_JOB_ID="$(sbatch --dependency="afterok:${SLURM_JOB_ID}" 'gsl@2.7.sh' | grep -o '[[:digit:]]*')"
STREAM_JOB_ID="$(sbatch --dependency="afterok:${SLURM_JOB_ID}" 'stream@5.10.sh' | grep -o '[[:digit:]]*')"
STREAM_OMP_JOB_ID="$(sbatch --dependency="afterok:${SLURM_JOB_ID}" 'stream@5.10-omp.sh' | grep -o '[[:digit:]]*')"
