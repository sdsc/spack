# Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import os


class Vasp(MakefilePackage):
    """
    The Vienna Ab initio Simulation Package (VASP)
    is a computer program for atomic scale materials modelling,
    e.g. electronic structure calculations
    and quantum-mechanical molecular dynamics, from first principles.
    """

    homepage = "http://vasp.at"
    url      = "file://{0}/vasp.5.4.4.tar.gz".format(os.getcwd())

    version('5.4.4', sha256='536957e45dd782b2d62ba0b2c94ef5e81d4110a6e0fd11239f8604afe0274642')
#    version('5.4.4', sha256='3a1f6ebe86796c259abf8717994592f0a880942dca83350e9ce09192cd816ef6')
#    version('5.4.4', sha256='5bd2449462386f01e575f9adf629c08cb03a13142806ffb6a71309ca4431cfb3')

    resource(name='vaspsol',
             git='https://github.com/henniggroup/VASPsol.git',
             tag='V1.0',
             when='+vaspsol')

    variant('scalapack', default=False,
            description='Enables build with SCALAPACK')

    variant('cuda', default=False,
            description='Enables running on Nvidia GPUs')

    variant('vaspsol', default=False,
            description='Enable VASPsol implicit solvation model\n'
            'https://github.com/henniggroup/VASPsol')

    depends_on('rsync', type='build')
    depends_on('blas')
    depends_on('lapack')
    depends_on('fftw')
    depends_on('mpi', type=('build', 'link', 'run'))
    depends_on('netlib-scalapack', when='+scalapack')
    depends_on('cuda', when='+cuda')

    conflicts('%gcc@:8', msg='GFortran before 9.x does not support all features needed to build VASP')
    conflicts('+vaspsol', when='+cuda', msg='+vaspsol only available for CPU')

    parallel = False

    def edit(self, spec, prefix):

        if '%gcc' in spec:
            make_include = join_path('arch', 'makefile.include.linux_gnu')
        else:
            make_include = join_path('arch',
                                     'makefile.include.linux_' +
                                     spec.compiler.name)

        os.rename(make_include, 'makefile.include')

        # This bunch of 'filter_file()' is to make these options settable
        # as environment variables
        filter_file('^CPP_OPTIONS[ ]{0,}=[ ]{0,}',
                    'CPP_OPTIONS ?= ',
                    'makefile.include')

        filter_file('^LIBDIR[ ]{0,}=.*$', '', 'makefile.include')
        filter_file('^BLAS[ ]{0,}=.*$', 'BLAS ?=', 'makefile.include')
        filter_file('^LAPACK[ ]{0,}=.*$', 'LAPACK ?=', 'makefile.include')
        filter_file('^FFTW[ ]{0,}?=.*$', 'FFTW ?=', 'makefile.include')
        filter_file('^MPI_INC[ ]{0,}=.*$', 'MPI_INC ?=', 'makefile.include')
        filter_file('-DscaLAPACK.*$\n', '', 'makefile.include')
        filter_file('^SCALAPACK*$', '', 'makefile.include')

        if '+cuda' in spec:
            filter_file('^OBJECTS_GPU[ ]{0,}=.*$',
                        'OBJECTS_GPU ?=',
                        'makefile.include')

            filter_file('^CPP_GPU[ ]{0,}=.*$',
                        'CPP_GPU ?=',
                        'makefile.include')

            filter_file('^CFLAGS[ ]{0,}=.*$',
                        'CFLAGS ?=',
                        'makefile.include')

        if '+vaspsol' in spec:
            copy('VASPsol/src/solvation.F', 'src/')

    def setup_build_environment(self, spack_env):
        spec = self.spec

        cpp_options = ['-DHOST=\\"LinuxGNU\\"', '-DMPI -DMPI_BLOCK=8000',
                       '-Duse_collective', '-DCACHE_SIZE=4000',
                       '-Davoidalloc', '-Duse_bse_te',
                       '-Dtbdyn', '-Duse_shmem']

        cflags = ['-fPIC', '-DADD_']

        spack_env.set('BLAS', spec['blas'].libs.ld_flags)
        spack_env.set('LAPACK', spec['lapack'].libs.ld_flags)
        spack_env.set('FFTW', spec['fftw'].prefix)
        spack_env.set('MPI_INC', spec['mpi'].prefix.include)

        if '+scalapack' in spec:
            cpp_options.append('-DscaLAPACK')
            spack_env.set('SCALAPACK', spec['netlib-scalapack'].libs.ld_flags)
     
        if '+cuda' in spec:
            cpp_gpu = ['-DCUDA_GPU', '-DRPROMU_CPROJ_OVERLAP',
                       '-DCUFFT_MIN=28', '-DUSE_PINNED_MEMORY']

            objects_gpu = ['fftmpiw.o', 'fftmpi_map.o', 'fft3dlib.o',
                           'fftw3d_gpu.o', 'fftmpiw_gpu.o']

            cflags.extend(['-DGPUSHMEM=300', '-DHAVE_CUBLAS'])

            spack_env.set('CUDA_ROOT', spec['cuda'].prefix)
            spack_env.set('CPP_GPU', ' '.join(cpp_gpu))
            spack_env.set('OBJECTS_GPU', ' '.join(objects_gpu))

        if '+vaspsol' in spec:
            cpp_options.append('-Dsol_compat')

        # Finally
        spack_env.set('CPP_OPTIONS', ' '.join(cpp_options))
        spack_env.set('CFLAGS', ' '.join(cflags))
        
    def build(self, spec, prefix):
        if '+cuda' in self.spec:
            make('gpu', 'gpu_ncl')
        else:
            make()

    def install(self, spec, prefix):
        install_tree('bin/', prefix.bin)
