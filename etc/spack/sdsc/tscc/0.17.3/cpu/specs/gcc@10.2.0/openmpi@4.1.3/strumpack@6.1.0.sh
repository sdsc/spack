#!/usr/bin/env bash

#SBATCH --job-name=strumpack@6.1.0
#SBATCH --account=sdsc
#SBATCH --partition=hotel
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='expanse'

declare -xr SPACK_VERSION='0.17.3'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR="$(HOME)/cm/shared/apps/spack/${SPACK_VERSION}/${SPACK_INSTANCE_NAME}"

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

# [mkandes@login02 spack]$ spack --show-cores=minimized spec -l strumpack@6.1.0 % gcc@10.2.0 +butterflypack +c_interface ~count_flops ~cuda ~ipo +mpi +openmp +parmetis ~rocm ~scotch +shared +slate ~task_timers +zfp "^butterflypack@2.0.0/$(spack find --format '{hash:7}' butterflypack@2.0.0 % ${SPACK_COMPILER} ^openmpi@4.1.3) ^slate@2021.05.02/$(spack find --format '{hash:7}' slate@2021.05.02 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
#Input spec
#--------------------------------
#strumpack@6.1.0%gcc@10.2.0+butterflypack+c_interface~count_flops~cuda~ipo+mpi+openmp+parmetis~rocm~scotch+shared+slate~task_timers+zfp
#    ^butterflypack@2.0.0%gcc@10.2.0~ipo+shared build_type=RelWithDebInfo arch=linux-rocky8-zen2
#        ^arpack-ng@3.7.0%gcc@10.2.0+mpi+shared arch=linux-rocky8-zen2
#            ^openblas@0.3.17%gcc@10.2.0~bignuma~consistent_fpcsr~ilp64+locking+pic+shared threads=none arch=linux-rocky8-zen2
#            ^openmpi@4.1.3%gcc@10.2.0~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix~singularity~sqlite3+static+thread_multiple+vt+wrapper-rpath fabrics=ucx schedulers=slurm arch=linux-rocky8-zen2
#                ^hwloc@2.6.0%gcc@10.2.0~cairo~cuda~gl~libudev+libxml2~netloc~nvml~opencl+pci~rocm+shared arch=linux-rocky8-zen2
#                    ^libpciaccess@0.16%gcc@10.2.0 arch=linux-rocky8-zen2
#                    ^libxml2@2.9.12%gcc@10.2.0~python arch=linux-rocky8-zen2
#                        ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-rocky8-zen2
#                        ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-rocky8-zen2
#                        ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-rocky8-zen2
#                    ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-rocky8-zen2
#                ^libevent@2.1.8%gcc@10.2.0+openssl arch=linux-rocky8-zen2
#                    ^openssl@1.1.1k%gcc@10.2.0~docs certs=system arch=linux-rocky8-zen2
#                ^lustre@2.12.8%gcc@10.2.0 arch=linux-rocky8-zen2
#                ^numactl@2.0.14%gcc@10.2.0 patches=4e1d78cbbb85de625bad28705e748856033eaafab92a66dffd383a3d7e00cc94,62fc8a8bf7665a60e8f4c93ebbd535647cebf74198f7afafec4c085a8825c006,ff37630df599cfabf0740518b91ec8daaf18e8f288b19adaae5364dc1f6b2296 arch=linux-rocky8-zen2
#                ^openssh@8.7p1%gcc@10.2.0 arch=linux-rocky8-zen2
#                    ^libedit@3.1-20210216%gcc@10.2.0 arch=linux-rocky8-zen2
#                ^pmix@3.2.1%gcc@10.2.0~docs+pmi_backwards_compatibility~restful arch=linux-rocky8-zen2
#                ^slurm@20.02.7%gcc@10.2.0~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc arch=linux-rocky8-zen2
#                ^ucx@1.10.1%gcc@10.2.0~assertions~cm~cma~cuda~dc~debug~dm~gdrcopy~ib-hw-tm~java~knem~logging~mlx5-dv+optimizations~parameter_checking+pic~rc~rocm+thread_multiple~ud~xpmem cuda_arch=none arch=linux-rocky8-zen2
#                    ^rdma-core@28.0%gcc@10.2.0~ipo build_type=RelWithDebInfo arch=linux-rocky8-zen2
#        ^netlib-scalapack@2.1.0%gcc@10.2.0~ipo+pic+shared build_type=Release patches=1c9ce5fee1451a08c2de3cc87f446aeda0b818ebbce4ad0d980ddf2f2a0b2dc4,f2baedde688ffe4c20943c334f580eb298e04d6f35c86b90a1f4e8cb7ae344a2 arch=linux-rocky8-zen2
#    ^slate@2021.05.02%gcc@10.2.0~cuda~ipo+mpi+openmp~rocm+shared amdgpu_target=none build_type=RelWithDebInfo cuda_arch=none arch=linux-rocky8-zen2
#        ^blaspp@2021.04.01%gcc@10.2.0~cuda~ipo+openmp~rocm+shared amdgpu_target=none build_type=RelWithDebInfo cuda_arch=none arch=linux-rocky8-zen2
#            ^openblas@0.3.17%gcc@10.2.0~bignuma~consistent_fpcsr~ilp64+locking+pic+shared threads=none arch=linux-rocky8-zen2
#        ^lapackpp@2021.04.00%gcc@10.2.0~ipo+shared build_type=RelWithDebInfo arch=linux-rocky8-zen2
#        ^netlib-scalapack@2.1.0%gcc@10.2.0~ipo+pic+shared build_type=Release patches=1c9ce5fee1451a08c2de3cc87f446aeda0b818ebbce4ad0d980ddf2f2a0b2dc4,f2baedde688ffe4c20943c334f580eb298e04d6f35c86b90a1f4e8cb7ae344a2 arch=linux-rocky8-zen2
#            ^openmpi@4.1.3%gcc@10.2.0~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix~singularity~sqlite3+static+thread_multiple+vt+wrapper-rpath fabrics=ucx schedulers=slurm arch=linux-rocky8-zen2
#                ^hwloc@2.6.0%gcc@10.2.0~cairo~cuda~gl~libudev+libxml2~netloc~nvml~opencl+pci~rocm+shared arch=linux-rocky8-zen2
#                    ^libpciaccess@0.16%gcc@10.2.0 arch=linux-rocky8-zen2
#                    ^libxml2@2.9.12%gcc@10.2.0~python arch=linux-rocky8-zen2
#                        ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-rocky8-zen2
#                        ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-rocky8-zen2
#                        ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-rocky8-zen2
#                    ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-rocky8-zen2
#                ^libevent@2.1.8%gcc@10.2.0+openssl arch=linux-rocky8-zen2
#                    ^openssl@1.1.1k%gcc@10.2.0~docs certs=system arch=linux-rocky8-zen2
#                ^lustre@2.12.8%gcc@10.2.0 arch=linux-rocky8-zen2
#                ^numactl@2.0.14%gcc@10.2.0 patches=4e1d78cbbb85de625bad28705e748856033eaafab92a66dffd383a3d7e00cc94,62fc8a8bf7665a60e8f4c93ebbd535647cebf74198f7afafec4c085a8825c006,ff37630df599cfabf0740518b91ec8daaf18e8f288b19adaae5364dc1f6b2296 arch=linux-rocky8-zen2
#                ^openssh@8.7p1%gcc@10.2.0 arch=linux-rocky8-zen2
#                    ^libedit@3.1-20210216%gcc@10.2.0 arch=linux-rocky8-zen2
#                ^pmix@3.2.1%gcc@10.2.0~docs+pmi_backwards_compatibility~restful arch=linux-rocky8-zen2
#                ^slurm@20.02.7%gcc@10.2.0~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc arch=linux-rocky8-zen2
#                ^ucx@1.10.1%gcc@10.2.0~assertions~cm~cma~cuda~dc~debug~dm~gdrcopy~ib-hw-tm~java~knem~logging~mlx5-dv+optimizations~parameter_checking+pic~rc~rocm+thread_multiple~ud~xpmem cuda_arch=none arch=linux-rocky8-zen2
#                    ^rdma-core@28.0%gcc@10.2.0~ipo build_type=RelWithDebInfo arch=linux-rocky8-zen2
#
#Concretized
#--------------------------------
#==> Error: strumpack@6.1.0%gcc@10.2.0+butterflypack+c_interface~count_flops~cuda~ipo+mpi+openmp+parmetis~rocm~scotch+shared+slate~task_timers+zfp ^arpack-ng@3.7.0%gcc@10.2.0+mpi+shared arch=linux-rocky8-zen2 ^blaspp@2021.04.01%gcc@10.2.0~cuda~ipo+openmp~rocm+shared amdgpu_target=none build_type=RelWithDebInfo cuda_arch=none arch=linux-rocky8-zen2 ^butterflypack@2.0.0%gcc@10.2.0~ipo+shared build_type=RelWithDebInfo arch=linux-rocky8-zen2 ^hwloc@2.6.0%gcc@10.2.0~cairo~cuda~gl~libudev+libxml2~netloc~nvml~opencl+pci~rocm+shared arch=linux-rocky8-zen2 ^hwloc@2.6.0%gcc@10.2.0~cairo~cuda~gl~libudev+libxml2~netloc~nvml~opencl+pci~rocm+shared arch=linux-rocky8-zen2 ^lapackpp@2021.04.00%gcc@10.2.0~ipo+shared build_type=RelWithDebInfo arch=linux-rocky8-zen2 ^libedit@3.1-20210216%gcc@10.2.0 arch=linux-rocky8-zen2 ^libedit@3.1-20210216%gcc@10.2.0 arch=linux-rocky8-zen2 ^libevent@2.1.8%gcc@10.2.0+openssl arch=linux-rocky8-zen2 ^libevent@2.1.8%gcc@10.2.0+openssl arch=linux-rocky8-zen2 ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-rocky8-zen2 ^libiconv@1.16%gcc@10.2.0 libs=shared,static arch=linux-rocky8-zen2 ^libpciaccess@0.16%gcc@10.2.0 arch=linux-rocky8-zen2 ^libpciaccess@0.16%gcc@10.2.0 arch=linux-rocky8-zen2 ^libxml2@2.9.12%gcc@10.2.0~python arch=linux-rocky8-zen2 ^libxml2@2.9.12%gcc@10.2.0~python arch=linux-rocky8-zen2 ^lustre@2.12.8%gcc@10.2.0 arch=linux-rocky8-zen2 ^lustre@2.12.8%gcc@10.2.0 arch=linux-rocky8-zen2 ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-rocky8-zen2 ^ncurses@6.2%gcc@10.2.0~symlinks+termlib abi=none arch=linux-rocky8-zen2 ^netlib-scalapack@2.1.0%gcc@10.2.0~ipo+pic+shared build_type=Release patches=1c9ce5fee1451a08c2de3cc87f446aeda0b818ebbce4ad0d980ddf2f2a0b2dc4,f2baedde688ffe4c20943c334f580eb298e04d6f35c86b90a1f4e8cb7ae344a2 arch=linux-rocky8-zen2 ^netlib-scalapack@2.1.0%gcc@10.2.0~ipo+pic+shared build_type=Release patches=1c9ce5fee1451a08c2de3cc87f446aeda0b818ebbce4ad0d980ddf2f2a0b2dc4,f2baedde688ffe4c20943c334f580eb298e04d6f35c86b90a1f4e8cb7ae344a2 arch=linux-rocky8-zen2 ^numactl@2.0.14%gcc@10.2.0 patches=4e1d78cbbb85de625bad28705e748856033eaafab92a66dffd383a3d7e00cc94,62fc8a8bf7665a60e8f4c93ebbd535647cebf74198f7afafec4c085a8825c006,ff37630df599cfabf0740518b91ec8daaf18e8f288b19adaae5364dc1f6b2296 arch=linux-rocky8-zen2 ^numactl@2.0.14%gcc@10.2.0 patches=4e1d78cbbb85de625bad28705e748856033eaafab92a66dffd383a3d7e00cc94,62fc8a8bf7665a60e8f4c93ebbd535647cebf74198f7afafec4c085a8825c006,ff37630df599cfabf0740518b91ec8daaf18e8f288b19adaae5364dc1f6b2296 arch=linux-rocky8-zen2 ^openblas@0.3.17%gcc@10.2.0~bignuma~consistent_fpcsr~ilp64+locking+pic+shared threads=none arch=linux-rocky8-zen2 ^openblas@0.3.17%gcc@10.2.0~bignuma~consistent_fpcsr~ilp64+locking+pic+shared threads=none arch=linux-rocky8-zen2 ^openmpi@4.1.3%gcc@10.2.0~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix~singularity~sqlite3+static+thread_multiple+vt+wrapper-rpath fabrics=ucx schedulers=slurm arch=linux-rocky8-zen2 ^openmpi@4.1.3%gcc@10.2.0~atomics~cuda~cxx~cxx_exceptions~gpfs~internal-hwloc~java+legacylaunchers+lustre~memchecker+pmi+pmix~singularity~sqlite3+static+thread_multiple+vt+wrapper-rpath fabrics=ucx schedulers=slurm arch=linux-rocky8-zen2 ^openssh@8.7p1%gcc@10.2.0 arch=linux-rocky8-zen2 ^openssh@8.7p1%gcc@10.2.0 arch=linux-rocky8-zen2 ^openssl@1.1.1k%gcc@10.2.0~docs certs=system arch=linux-rocky8-zen2 ^openssl@1.1.1k%gcc@10.2.0~docs certs=system arch=linux-rocky8-zen2 ^pmix@3.2.1%gcc@10.2.0~docs+pmi_backwards_compatibility~restful arch=linux-rocky8-zen2 ^pmix@3.2.1%gcc@10.2.0~docs+pmi_backwards_compatibility~restful arch=linux-rocky8-zen2 ^rdma-core@28.0%gcc@10.2.0~ipo build_type=RelWithDebInfo arch=linux-rocky8-zen2 ^rdma-core@28.0%gcc@10.2.0~ipo build_type=RelWithDebInfo arch=linux-rocky8-zen2 ^slate@2021.05.02%gcc@10.2.0~cuda~ipo+mpi+openmp~rocm+shared amdgpu_target=none build_type=RelWithDebInfo cuda_arch=none arch=linux-rocky8-zen2 ^slurm@20.02.7%gcc@10.2.0~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc arch=linux-rocky8-zen2 ^slurm@20.02.7%gcc@10.2.0~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc arch=linux-rocky8-zen2 ^ucx@1.10.1%gcc@10.2.0~assertions~cm~cma~cuda~dc~debug~dm~gdrcopy~ib-hw-tm~java~knem~logging~mlx5-dv+optimizations~parameter_checking+pic~rc~rocm+thread_multiple~ud~xpmem cuda_arch=none arch=linux-rocky8-zen2 ^ucx@1.10.1%gcc@10.2.0~assertions~cm~cma~cuda~dc~debug~dm~gdrcopy~ib-hw-tm~java~knem~logging~mlx5-dv+optimizations~parameter_checking+pic~rc~rocm+thread_multiple~ud~xpmem cuda_arch=none arch=linux-rocky8-zen2 ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-rocky8-zen2 ^xz@5.2.5%gcc@10.2.0~pic libs=shared,static arch=linux-rocky8-zen2 ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-rocky8-zen2 ^zlib@1.2.11%gcc@10.2.0+optimize+pic+shared arch=linux-rocky8-zen2 is unsatisfiable, conflicts are:
#  condition(3180)
#  condition(5069)
#  dependency_type(5069,"build")
#  hash("butterflypack","772u22jhdeopeedyynbgjxzoiggiwb74")
#  imposed_constraint("772u22jhdeopeedyynbgjxzoiggiwb74","hash","openblas","fxzqxj3ljgy5sox5pq7e4sjtqrt75pqf")
#  imposed_constraint("fxzqxj3ljgy5sox5pq7e4sjtqrt75pqf","node","openblas")
#  imposed_constraint(5069,"variant_set","openblas","threads","openmp")
#  root("strumpack")
#  variant_condition(3180,"openblas","threads")
#
# i.e., +openmp requires openblas with +openmp, but we've been using threads=none as default openblas for all packages. arpack-ng may be the package required with openblas-omp

declare -xr SPACK_PACKAGE='strumpack@6.1.0'
declare -xr SPACK_COMPILER='gcc@10.2.0'
declare -xr SPACK_VARIANTS='+butterflypack +c_interface ~count_flops ~cuda ~ipo +mpi ~openmp +parmetis ~rocm ~scotch +shared +slate ~task_timers +zfp'
declare -xr SPACK_DEPENDENCIES="^butterflypack@2.0.0/$(spack find --format '{hash:7}' butterflypack@2.0.0 % ${SPACK_COMPILER} ^openmpi@4.1.3) ^slate@2021.05.02/$(spack find --format '{hash:7}' slate@2021.05.02 % ${SPACK_COMPILER} ^openmpi@4.1.3)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} $butterflypackNCIES}"

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
