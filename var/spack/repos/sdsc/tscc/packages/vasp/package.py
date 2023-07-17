# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

import os
import glob

from spack import *


class Vasp(MakefilePackage):
    """
    The Vienna Ab initio Simulation Package (VASP)
    is a computer program for atomic scale materials modelling,
    e.g. electronic structure calculations
    and quantum-mechanical molecular dynamics, from first principles.
    """

    homepage = "https://vasp.at"
    url      = "file://{0}/vasp.5.4.4.pl2.tgz".format(os.getcwd())
    manual_download = True

    version('6.4.0', sha256='34399c61694babbc23b5b8823d5d3634d7cd5ad0a622af4c108e2843ed344af8')

    resource(name='vaspsol',
             git='https://github.com/henniggroup/VASPsol.git',
             tag='V1.0',
             when='+vaspsol')

    variant('openmp', default=False,
            description='Enable openmp build')

    variant('scalapack', default=False,
            description='Enables build with SCALAPACK')

    variant('acc', default=False,
            description='Enables running on Nvidia GPUs')

    variant('vaspsol', default=False,
            description='Enable VASPsol implicit solvation model\n'
            'https://github.com/henniggroup/VASPsol')

    depends_on('rsync', type='build')
    depends_on('blas')
    depends_on('lapack')
    depends_on('fftw-api')
    depends_on('mpi', type=('build', 'link', 'run'))
    depends_on('scalapack', when='+scalapack')
    depends_on('qd', when='%nvhpc')

    conflicts('%gcc@:8', msg='GFortran before 9.x does not support all features needed to build VASP')
    conflicts('+vaspsol', when='acc', msg='+vaspsol only available for CPU')
    conflicts('+openmp', when='@:6.1.1', msg='openmp support started from 6.2')

    parallel = False

    def edit(self, spec, prefix):

        if '%gcc' in spec:
            if '+openmp' in spec:
                make_include = join_path('arch', 'makefile.include.linux_gnu_omp')
            else:
                make_include = join_path('arch', 'makefile.include.linux_gnu')
        elif '%nvhpc' in spec:
            if spec['blas'].name == 'intel-mkl' :
                if '+acc' in spec:         
                    make_include = join_path('arch','makefile.include.nvhpc_ompi_mkl_omp_acc')
                else:
                    make_include = join_path('arch','makefile.include.nvhpc_ompi_mkl_omp')
            else:
                if '+acc' in spec:         
                    if '+openmp' in spec:
                        make_include = join_path('arch','makefile.include.nvhpc_omp_acc')
                    else:
                        make_include = join_path('arch','makefile.include.nvhpc_acc')
        elif '%aocc' in spec:
            if '+openmp' in spec:
                copy(
                    join_path('arch', 'makefile.include.linux_gnu_omp'),
                    join_path('arch', 'makefile.include.linux_aocc_omp')
                )
                make_include = join_path('arch', 'makefile.include.linux_aocc_omp')
            else:
                copy(
                    join_path('arch', 'makefile.include.linux_gnu'),
                    join_path('arch', 'makefile.include.linux_aocc')
                )
                make_include = join_path('arch', 'makefile.include.linux_aocc')
            filter_file(
                'gcc', '{0} {1}'.format(spack_cc, '-Mfree'),
                make_include, string=True
            )
            filter_file('g++', spack_cxx, make_include, string=True)
            filter_file('^CFLAGS_LIB[ ]{0,}=.*$',
                        'CFLAGS_LIB = -O3', make_include)
            filter_file('^FFLAGS_LIB[ ]{0,}=.*$',
                        'FFLAGS_LIB = -O2', make_include)
            filter_file('^OFLAG[ ]{0,}=.*$',
                        'OFLAG = -O3', make_include)
            filter_file('^FC[ ]{0,}=.*$',
                        'FC = {0}'.format(spec['mpi'].mpifc),
                        make_include, string=True)
            filter_file('^FCL[ ]{0,}=.*$',
                        'FCL = {0}'.format(spec['mpi'].mpifc),
                        make_include, string=True)
        else:
            if '+openmp' in spec:
                make_include = join_path('arch',
                                         'makefile.include.{0}_omp'.
                                         format(spec.compiler.name))
            else:
                make_include = join_path('arch',
                                         'makefile.include.' + spec.compiler.name)
         
            
        os.rename(make_include, 'makefile.include')

        if '%intel' in spec:
            filter_file('qmkl','mkl','makefile.include')

        filter_file('OBJECTS_LIB = linpack_double.o','OBJECTS_LIB = linpack_double.o getshmem.o','makefile.include')

        # This bunch of 'filter_file()' is to make these options settable
        # as environment variables
        filter_file('^CPP_OPTIONS[ ]{0,}=[ ]{0,}',
                    'CPP_OPTIONS ?= ',
                    'makefile.include')
        filter_file('^FFLAGS[ ]{0,}=[ ]{0,}',
                    'FFLAGS ?= ',
                    'makefile.include')

        filter_file('^LIBDIR[ ]{0,}=.*$', '', 'makefile.include')
        filter_file('^BLAS[ ]{0,}=.*$', 'BLAS ?=', 'makefile.include')
        filter_file('^LAPACK[ ]{0,}=.*$', 'LAPACK ?=', 'makefile.include')
        filter_file('^FFTW[ ]{0,}?=.*$', 'FFTW ?=', 'makefile.include')
        filter_file('^MPI_INC[ ]{0,}=.*$', 'MPI_INC ?=', 'makefile.include')
        filter_file('-DscaLAPACK.*$\n', '', 'makefile.include')
        filter_file('^SCALAPACK[ ]{0,}=.*$', 'SCALAPACK ?=', 'makefile.include')

        if '+vaspsol' in spec:
            copy('VASPsol/src/solvation.F', 'src/')

        if spec['blas'].name == 'intel-mkl':
            filter_file(r'INCS.*=.*FFTW.*/include','INCS = -I'+join_path(spec['intel-mkl'].prefix,'compilers_and_libraries_'+str(spec['intel-mkl'].version),'linux','mkl','include','fftw'),'makefile.include')
            filter_file(r'LLIBS.*lfftw3.*','','makefile.include')

        if '+acc' in spec:
            filter_file('cuda11.0','cuda11.5','makefile.include')

    def setup_build_environment(self, spack_env):
        spec = self.spec

        cpp_options = ['-DMPI -DMPI_BLOCK=8000',
                       '-Duse_collective', '-DCACHE_SIZE=4000',
                       '-Davoidalloc', '-Duse_bse_te',
                       '-Dtbdyn', '-Duse_shmem','-Dfock_dblbuf']
        if '+openmp' in self.spec:
            cpp_options.extend(['-D_OPENMP'])
        if '%aocc' in self.spec:
            cpp_options.extend(['-DHOST=\\"LinuxGNU\\"',
                                '-Dfock_dblbuf'])
        else:
            cpp_options.append('-DHOST=\\"LinuxGNU\\"')

        if self.spec.satisfies('@6:'):
            cpp_options.append('-Dvasp6')

        cflags = ['-fPIC', '-DADD_']
        fflags = []
        if '%gcc' in spec or '%intel' in spec:
            fflags.append('-w')
        elif '%nvhpc' in spec:
            fflags.extend(['-Mnoupcase', '-Mbackslash', '-Mlarge_arrays'])
        elif '%aocc' in spec:
            fflags.extend(['-fno-fortran-main', '-Mbackslash', '-ffast-math'])

        spack_env.set('BLAS', spec['blas'].libs.ld_flags)
        spack_env.set('LAPACK', spec['lapack'].libs.ld_flags)
        spack_env.set('FFTW', spec['fftw-api'].prefix)
        spack_env.set('MPI_INC', spec['mpi'].prefix.include)

        if '%nvhpc' in spec:
            spack_env.set('QD', spec['qd'].prefix)

        if '+acc' in spec:
            cpp_options.extend(['-DMPI_INPLACE','-D_OPENACC','-DUSENCCL','-DUSENCCLP2P'])

        if '%nvhpc' in spec:
            cpp_options.append('-Dqd_emulate')

        if '+scalapack' in spec:
            cpp_options.append('-DscaLAPACK')
            spack_env.set('SCALAPACK', spec['scalapack'].libs.ld_flags)

        if '+vaspsol' in spec:
            cpp_options.append('-Dsol_compat')

        if spec.satisfies('%gcc@10:'):
            fflags.append('-fallow-argument-mismatch')

        # Finally
        spack_env.set('CPP_OPTIONS', ' '.join(cpp_options))
        spack_env.set('FFLAGS', ' '.join(fflags))

        if '%nvhpc' in spec:
            spack_env.prepend_path('LD_LIBRARY_PATH',join_path(spec['mpi'].prefix,'lib'))
            nvc_cuda_path = join_path(ancestor(self.compiler.cc, 3),'cuda')
            nvc_cuda_path =  glob.glob(join_path(nvc_cuda_path,'*'))[0]
            spack_env.set('NVHPC_CUDA_HOME',nvc_cuda_path)
            spack_env.prepend_path('PATH',join_path(nvc_cuda_path,'bin'))
            spack_env.prepend_path('LD_LIBRARY_PATH',join_path(nvc_cuda_path,'targets','x86_64-linux','lib'))


    def build(self, spec, prefix):
        make('std', 'gam', 'ncl')

    def install(self, spec, prefix):
        install_tree('bin/', prefix.bin)

#   @run_after('install')
#   def install_test(self):
#       mkdirp(join_path(self.prefix,'test'))
#       with working_dir(self.prefix.test):
#          tar=which('tar')
#          tar('xvzf',join_path(os.path.dirname(self.module.__file__),'H2O.tgz'))
#          with working_dir('H2O'):
#              if self.spec['mpi'].name == 'mvapich2' and 'slurm' in str(self.spec['mpi'].token):
#                  output=Executable('srun')('-n','4','--mpi=pmi2',join_path(self.prefix.bin,'vasp_std'),output=str,error=str)
#              else:
#                  output=Executable('mpirun')('-np','4',join_path(self.prefix.bin,'vasp_std'),output=str,error=str)
#              teststring='F= -.14223'
#              if teststring in output:
#                  print("PASSED")
#              else:
#                  print("FAILED")
