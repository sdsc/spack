#!/usr/bin/env bash

#SBATCH --job-name=deploy
#SBATCH --account=use300
#SBATCH --clusters=expanse
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00
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

cp -p "${SPACK_INSTANCE_DIR}/etc/spack/sdsc/expanse/0.17.3/cpu/dev/yamls/compilers.yaml" "${SPACK_INSTANCE_DIR}/etc/spack/compilers.yaml"
cp -p "${SPACK_INSTANCE_DIR}/etc/spack/sdsc/expanse/0.17.3/cpu/dev/yamls/modules.yaml" "${SPACK_INSTANCE_DIR}/etc/spack/modules.yaml"
cp -p "${SPACK_INSTANCE_DIR}/etc/spack/sdsc/expanse/0.17.3/cpu/dev/yamls/packages.yaml" "${SPACK_INSTANCE_DIR}/etc/spack/packages.yaml"

spack find aocc@3.2.0 % gcc@8.5.0
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: You must first manually run:'
  echo '  spack install aocc@3.2.0 % gcc@8.5.0 +license-agreed'
  exit 1
fi

sed -i "s|PATH_TO_AMD_CLANG_3_2_0|$(spack location -i 'aocc@3.2.0')/bin/clang|g" "${SPACK_INSTANCE_DIR}/etc/spack/compilers.yaml"
sed -i "s|PATH_TO_AMD_CLANG++_3_2_0|$(spack location -i 'aocc@3.2.0')/bin/clang++|g" "${SPACK_INSTANCE_DIR}/etc/spack/compilers.yaml"
sed -i "s|PATH_TO_AMD_FLANG_3_2_0|$(spack location -i 'aocc@3.2.0')/bin/flang|g" "${SPACK_INSTANCE_DIR}/etc/spack/compilers.yaml"
sed -i "s|PATH_TO_AMD_FLANG_3_2_0|$(spack location -i 'aocc@3.2.0')/bin/flang|g" "${SPACK_INSTANCE_DIR}/etc/spack/compilers.yaml"

cd "${SLURM_SUBMIT_DIR}/specs"
GCC_JOB_ID="$(sbatch 'gcc@10.2.0.sh' | grep -o '[[:digit:]]*')"

cd "${SLURM_SUBMIT_DIR}/specs/gcc@10.2.0"
CMAKE_JOB_ID="$(sbatch --dependency="afterok:${GCC_JOB_ID}" 'cmake@3.21.4.sh' | grep -o '[[:digit:]]*')"
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
            ADIOS2_JOB_ID="$(sbatch --dependency="afterok:${NUMPY_JOB_ID}" 'adios2@2.7.1.sh' | grep -o '[[:digit:]]*')"
            BOOST_JOB_ID="$(sbatch --dependency="afterok:${NUMPY_JOB_ID}" 'boost@1.77.0.sh' | grep -o '[[:digit:]]*')"
              CGAL4_JOB_ID="$(sbatch --dependency="afterok:${BOOST_JOB_ID}" 'cgal@4.13.sh' | grep -o '[[:digit:]]*')"
              CGAL5_JOB_ID="$(sbatch --dependency="afterok:${BOOST_JOB_ID}" 'cgal@5.0.3.sh' | grep -o '[[:digit:]]*')"
              IQTREE_JOB_ID="$(sbatch --dependency="afterok:${BOOST_JOB_ID}" 'iq-tree@2.1.3.sh' | grep -o '[[:digit:]]*')"
                MVAPICH2_JOB_ID="$(sbatch --dependency="afterok:${IQTREE_JOB_ID}" 'mvapich2@2.3.7.sh' | grep -o '[[:digit:]]*')"
                UCX_JOB_ID="$(sbatch --dependency="afterok:${IQTREE_JOB_ID}" 'ucx@1.10.1.sh' | grep -o '[[:digit:]]*')"
                  OPENMPI_JOB_ID="$(sbatch --dependency="afterok:${UCX_JOB_ID}" 'openmpi@4.1.3.sh' | grep -o '[[:digit:]]*')"
          NUMPY_I64_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_I64_JOB_ID}" 'py-numpy@1.21.3-i64.sh' | grep -o '[[:digit:]]*')"
          NUMPY_OMP_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_OMP_JOB_ID}" 'py-numpy@1.21.3-omp.sh' | grep -o '[[:digit:]]*')"
          NUMPY_I64_JOB_ID="$(sbatch --dependency="afterok:${CYTHON_JOB_ID}:${OPENBLAS_I64_OMP_JOB_ID}" 'py-numpy@1.21.3-i64-omp.sh' | grep -o '[[:digit:]]*')"
        PIP_JOB_ID="$(sbatch --dependency="afterok:${SETUPTOOLS_JOB_ID}" 'py-pip@21.1.2.sh' | grep -o '[[:digit:]]*')"
        VENV_JOB_ID="$(sbatch --dependency="afterok:${SETUPTOOLS_JOB_ID}" 'py-virtualenv@16.7.6.sh' | grep -o '[[:digit:]]*')"
FFTW_JOB_ID="$(sbatch --dependency="afterok:${GCC_JOB_ID}" 'fftw@3.3.10.sh' | grep -o '[[:digit:]]*')"
FFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${GCC_JOB_ID}" 'fftw@3.3.10-omp.sh' | grep -o '[[:digit:]]*')"
  GSL_JOB_ID="$(sbatch --dependency="afterok:${GCC_JOB_ID}" 'gsl@2.7.sh' | grep -o '[[:digit:]]*')"
  STREAM_JOB_ID="$(sbatch --dependency="afterok:${GCC_JOB_ID}" 'stream@5.10.sh' | grep -o '[[:digit:]]*')"
  STREAM_OMP_JOB_ID="$(sbatch --dependency="afterok:${GCC_JOB_ID}" 'stream@5.10-omp.sh' | grep -o '[[:digit:]]*')"

cd "${SLURM_SUBMIT_DIR}/specs/gcc@10.2.0/mvapich2@2.3.7"
AMDFFTW_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'amdfftw@3.1.sh' | grep -o '[[:digit:]]*')"
AMDFFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'amdfftw@3.1-omp.sh' | grep -o '[[:digit:]]*')"
AMDSCALAPACK_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'amdscalapack@3.1.sh' | grep -o '[[:digit:]]*')"
BOOST_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'boost@1.77.0.sh' | grep -o '[[:digit:]]*')"
CHARMPP_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'charmpp@6.10.2.sh' | grep -o '[[:digit:]]*')"
  NAMD2_JOB_ID="$(sbatch --dependency="afterok:${CHARMPP_JOB_ID}" 'namd@2.14.sh' | grep -o '[[:digit:]]*')"
FFTW_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'fftw@3.3.10.sh' | grep -o '[[:digit:]]*')"
FFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'fftw@3.3.10-omp.sh' | grep -o '[[:digit:]]*')"
GROMACS_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'gromacs@2022.6.sh' | grep -o '[[:digit:]]*')"
HDF5_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'hdf5@1.10.7.sh' | grep -o '[[:digit:]]*')"
HPL_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'hpl@2.3.sh' | grep -o '[[:digit:]]*')"
HPL_I64_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'hpl@2.3-i64.sh' | grep -o '[[:digit:]]*')"
HPL_OMP_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'hpl@2.3-omp.sh' | grep -o '[[:digit:]]*')"
HPL_I64_OMP_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'hpl@2.3-i64.sh' | grep -o '[[:digit:]]*')"
IQTREE_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'iq-tree@2.1.3.sh' | grep -o '[[:digit:]]*')"
KAHIP_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'kahip@3.11.sh' | grep -o '[[:digit:]]*')"
MPI4PY_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'py-mpi4py@3.1.2.sh' | grep -o '[[:digit:]]*')"
  ADIOS2_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${MPI4PY_JOB_ID}" 'adios2@2.7.1.sh' | grep -o '[[:digit:]]*')"
  NEURON_JOB_ID="$(sbatch --dependency="afterok:${MPI4PY_JOB_ID}" 'neuron@8.0.0.sh' | grep -o '[[:digit:]]*')"
NETLIB_SCALAPACK_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'netlib-scalapack@2.1.0.sh' | grep -o '[[:digit:]]*')"
  ELPA_JOB_ID="$(sbatch --dependency="afterok:${NETLIB_SCALAPACK_JOB_ID}" 'elpa@2021.05.001.sh' | grep -o '[[:digit:]]*')"
    QUANTUM_ESPRESSO_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${ELPA_JOB_ID}" 'quantum-espresso@7.0.sh' | grep -o '[[:digit:]]*')"
OMB_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'osu-micro-benchmarks@5.7.1.sh' | grep -o '[[:digit:]]*')"
PARALLEL_NETCDF_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'parallel-netcdf@1.12.2.sh' | grep -o '[[:digit:]]*')"
  IOR_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${PARALLEL_NETCDF_JOB_ID}" 'ior@3.3.0.sh' | grep -o '[[:digit:]]*')"
  NETCDF_C_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${PARALLEL_NETCDF_JOB_ID}" 'netcdf-c@4.8.1.sh' | grep -o '[[:digit:]]*')"
    NETCDF_CXX4_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_C_JOB_ID}" 'netcdf-cxx4@4.3.1.sh' | grep -o '[[:digit:]]*')"
    NETCDF_FORTRAN_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_C_JOB_ID}" 'netcdf-fortran@4.5.3.sh' | grep -o '[[:digit:]]*')"
      WRF_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_FORTRAN_JOB_ID}" 'wrf@4.2.sh' | grep -o '[[:digit:]]*')"
        WPS_JOB_ID="$(sbatch --dependency="afterok:${WRF_JOB_ID}" 'wps@4.2.sh' | grep -o '[[:digit:]]*')"
PARMETIS_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'parmetis@4.0.3.sh' | grep -o '[[:digit:]]*')"
  ZOLTAN_JOB_ID="$(sbatch --dependency="afterok:${PARMETIS_JOB_ID}" 'zoltan@3.83.sh' | grep -o '[[:digit:]]*')"
RAXML_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'raxml@8.2.12.sh' | grep -o '[[:digit:]]*')"
RAXML_NG_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'raxml-ng@1.0.2.sh' | grep -o '[[:digit:]]*')"
SCOTCH_JOB_ID="$(sbatch --dependency="afterok:${MVAPICH2_JOB_ID}" 'scotch@6.1.1.sh' | grep -o '[[:digit:]]*')"
  OPENFOAM_JOB_ID="$(sbatch --dependency="afterok:${ADIOS2_JOB_ID}:${SCOTCH_JOB_ID}:${ZOLTAN_JOB_ID}" 'openfoam@2106.sh' | grep -o '[[:digit:]]*')"

cd "${SLURM_SUBMIT_DIR}/specs/gcc@10.2.0/openmpi@4.1.3"
AMDFFTW_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'amdfftw@3.1.sh' | grep -o '[[:digit:]]*')"
AMDFFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'amdfftw@3.1-omp.sh' | grep -o '[[:digit:]]*')"
AMDSCALAPACK_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'amdscalapack@3.1.sh' | grep -o '[[:digit:]]*')"
BOOST_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'boost@1.77.0.sh' | grep -o '[[:digit:]]*')"
CHARMPP_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'charmpp@6.10.2.sh' | grep -o '[[:digit:]]*')"
  NAMD2_JOB_ID="$(sbatch --dependency="afterok:${CHARMPP_JOB_ID}" 'namd@2.14.sh' | grep -o '[[:digit:]]*')"
FFTW_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'fftw@3.3.10.sh' | grep -o '[[:digit:]]*')"
FFTW_OMP_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'fftw@3.3.10-omp.sh' | grep -o '[[:digit:]]*')"
GROMACS_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'gromacs@2022.6.sh' | grep -o '[[:digit:]]*')"
HDF5_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'hdf5@1.10.7.sh' | grep -o '[[:digit:]]*')"
HPL_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'hpl@2.3.sh' | grep -o '[[:digit:]]*')"
HPL_I64_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'hpl@2.3-i64.sh' | grep -o '[[:digit:]]*')"
HPL_OMP_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'hpl@2.3-omp.sh' | grep -o '[[:digit:]]*')"
HPL_I64_OMP_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'hpl@2.3-i64.sh' | grep -o '[[:digit:]]*')"
IQTREE_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'iq-tree@2.1.3.sh' | grep -o '[[:digit:]]*')"
KAHIP_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'kahip@3.11.sh' | grep -o '[[:digit:]]*')"
MPI4PY_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'py-mpi4py@3.1.2.sh' | grep -o '[[:digit:]]*')"
  ADIOS2_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${MPI4PY_JOB_ID}" 'adios2@2.7.1.sh' | grep -o '[[:digit:]]*')"
  NEURON_JOB_ID="$(sbatch --dependency="afterok:${MPI4PY_JOB_ID}" 'neuron@8.0.0.sh' | grep -o '[[:digit:]]*')"
NETLIB_SCALAPACK_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'netlib-scalapack@2.1.0.sh' | grep -o '[[:digit:]]*')"
  ELPA_JOB_ID="$(sbatch --dependency="afterok:${NETLIB_SCALAPACK_JOB_ID}" 'elpa@2021.05.001.sh' | grep -o '[[:digit:]]*')"
    QUANTUM_ESPRESSO_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${ELPA_JOB_ID}" 'quantum-espresso@7.0.sh' | grep -o '[[:digit:]]*')"
OMB_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'osu-micro-benchmarks@5.7.1.sh' | grep -o '[[:digit:]]*')"
PARALLEL_NETCDF_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'parallel-netcdf@1.12.2.sh' | grep -o '[[:digit:]]*')"
  IOR_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${PARALLEL_NETCDF_JOB_ID}" 'ior@3.3.0.sh' | grep -o '[[:digit:]]*')"
  NETCDF_C_JOB_ID="$(sbatch --dependency="afterok:${HDF5_JOB_ID}:${PARALLEL_NETCDF_JOB_ID}" 'netcdf-c@4.8.1.sh' | grep -o '[[:digit:]]*')"
    NETCDF_CXX4_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_C_JOB_ID}" 'netcdf-cxx4@4.3.1.sh' | grep -o '[[:digit:]]*')"
    NETCDF_FORTRAN_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_C_JOB_ID}" 'netcdf-fortran@4.5.3.sh' | grep -o '[[:digit:]]*')"
      WRF_JOB_ID="$(sbatch --dependency="afterok:${NETCDF_FORTRAN_JOB_ID}" 'wrf@4.2.sh' | grep -o '[[:digit:]]*')"
        WPS_JOB_ID="$(sbatch --dependency="afterok:${WRF_JOB_ID}" 'wps@4.2.sh' | grep -o '[[:digit:]]*')"
PARMETIS_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'parmetis@4.0.3.sh' | grep -o '[[:digit:]]*')"
  ZOLTAN_JOB_ID="$(sbatch --dependency="afterok:${PARMETIS_JOB_ID}" 'zoltan@3.83.sh' | grep -o '[[:digit:]]*')"
RAXML_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'raxml@8.2.12.sh' | grep -o '[[:digit:]]*')"
RAXML_NG_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'raxml-ng@1.0.2.sh' | grep -o '[[:digit:]]*')"
SCOTCH_JOB_ID="$(sbatch --dependency="afterok:${OPENMPI_JOB_ID}" 'scotch@6.1.1.sh' | grep -o '[[:digit:]]*')"
  OPENFOAM_JOB_ID="$(sbatch --dependency="afterok:${ADIOS2_JOB_ID}:${SCOTCH_JOB_ID}:${ZOLTAN_JOB_ID}" 'openfoam@2106.sh' | grep -o '[[:digit:]]*')"
