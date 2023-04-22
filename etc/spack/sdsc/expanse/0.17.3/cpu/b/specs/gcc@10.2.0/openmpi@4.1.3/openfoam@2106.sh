#!/usr/bin/env bash

#SBATCH --job-name=openfoam@2106
#SBATCH --account=use300
#SBATCH --reservation=rocky8u7_testing
#SBATCH --partition=ind-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr LOCAL_SCRATCH_DIR="/scratch/${USER}/job_${SLURM_JOB_ID}"
declare -xr TMPDIR="${LOCAL_SCRATCH_DIR}"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_VERSION='b'
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

# >> 11774    /usr/lib64/libOpenGL.so: undefined reference to `_glapi_tls_Curre
#              nt'
#  >> 11775    collect2: error: ld returned 1 exit status
#  >> 11776    make[2]: *** [Rendering/OpenGL2/CMakeFiles/vtkProbeOpenGLVersion.
#              dir/build.make:116: bin/vtkProbeOpenGLVersion-9.0] Error 1
#     11777    make[2]: Leaving directory '/scratch/mkandes/job_358/spack-stage/
#              spack-stage/spack-stage-vtk-9.0.3-ic6r6nysowcyrt4kaf5sie55675bex3
#              x/spack-build-ic6r6ny'
#  >> 11778    make[1]: *** [CMakeFiles/Makefile2:8018: Rendering/OpenGL2/CMakeF
#              iles/vtkProbeOpenGLVersion.dir/all] Error 2

# ==> Installing vtk-9.0.3-ic6r6nysowcyrt4kaf5sie55675bex3x
# ==> No binary for vtk-9.0.3-ic6r6nysowcyrt4kaf5sie55675bex3x found: installing from source
# ==> Fetching https://mirror.spack.io/_source-cache/archive/bc/bc3eb9625b2b8dbfecb6052a2ab091fc91405de4333b0ec68f3323815154ed8a.tar.gz
# ==> Fetching https://mirror.spack.io/_source-cache/archive/05/0546696bd02f3a99fccb9b7c49533377bf8179df16d901cefe5abf251173716d
# ==> Applied patch https://gitlab.kitware.com/vtk/vtk/-/commit/e066c3f4fbbfe7470c6207db0fc3f3952db633c.diff
# ==> vtk: Executing phase: 'cmake'
# ==> vtk: Executing phase: 'build'
# ==> Error: ProcessError: Command exited with status 2:
#    'make' '-j16'
#
# 4 errors found in build log:
# ...
# >> 11422    /usr/lib64/libOpenGL.so: undefined reference to `_glapi_tls_Curre
#              nt'
#  >> 11423    collect2: error: ld returned 1 exit status
#  >> 11424    make[2]: *** [Rendering/OpenGL2/CMakeFiles/vtkProbeOpenGLVersion.
#              dir/build.make:116: bin/vtkProbeOpenGLVersion-9.0] Error 1
#     11425    make[2]: Leaving directory '/scratch/spack_cpu/job_21721686/spack
#              -stage/spack-stage-vtk-9.0.3-ic6r6nysowcyrt4kaf5sie55675bex3x/spa
#              ck-build-ic6r6ny'
#  >> 11426    make[1]: *** [CMakeFiles/Makefile2:8018: Rendering/OpenGL2/CMakeF
#              iles/vtkProbeOpenGLVersion.dir/all] Error 2

declare -xr SPACK_PACKAGE='openfoam@2106'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='~float32 ~int64 ~kahip ~knl +metis +mgridgen +paraview +scotch +source ~spdp +vtk ~zoltan'
declare -xr SPACK_DEPENDENCIES="^boost@1.77.0/$(spack find --format '{hash:7}' boost@1.77.0 % ${SPACK_COMPILER} ~mpi) ^cgal@4.13/$(spack find --format '{hash:7}' cgal@4.13 % ${SPACK_COMPILER}) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^metis@5.1.0/$(spack find --format '{hash:7}' metis@5.1.0 % ${SPACK_COMPILER} ~int64 ~real64) ^paraview@5.9.1/$(spack find --format '{hash:7}' paraview@5.9.1 % ${SPACK_COMPILER} +mpi ^openmpi@4.1.3) ^scotch@6.1.1/$(spack find --format '{hash:7}' scotch@6.1.1 % ${SPACK_COMPILER} ~int64 +mpi ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack --show-cores=minimized spec --long --namespaces --types "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'wrf@4.2.sh'

sleep 30
