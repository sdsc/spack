# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
# ----------------------------------------------------------------------------

from spack import *
import os
import subprocess
import shutil
import glob


class Amber(Package,CudaPackage):
    """Amber is a suite of biomolecular simulation programs.

       Note: A manual download is required for Amber.
       Spack will search your current directory for the download file.
       Alternatively, add this file to a mirror so that Spack can find it.
       For instructions on how to set up a mirror, see
       http://spack.readthedocs.io/en/latest/mirrors.html"""

    homepage = "http://ambermd.org/"
    url      = "file://{0}/Amber22.tar.bz2".format(os.getcwd())


    version('22', sha256='3c887ccbad690fc76ff0b120a3448eae023c08e76582aac07900d4a9708ebd16')

    resources = [
      # [version amber, version ambertools , sha256sum]
        ('22', '23', 'debb52e6ef2e1b4eaa917a8b4d4934bd2388659c660501a81ea044903bf9ee9d'),
    ]

    for ver, ambertools_ver, checksum in resources:
        resource(when='@{0}'.format(ver),
                 name='AmberTools',
                 url='file://{0}/AmberTools{1}.tar.bz2'.format(os.getcwd(),
                                                               ambertools_ver),
                 sha256=checksum,
                 destination='',
                 placement='ambertools_tmpdir',
                 )

    variant('mpi', description='Build MPI executables',
            default=True)
    variant('openmp', description='Use OpenMP pragmas to parallelize',
            default=True)
    variant('cuda', description='Build cuda execuatables',
            default=False)
    variant('update', description='Update the sources prior compilation',
            default=True)
    depends_on('zlib')
    depends_on('flex', type='build')
    depends_on('bison', type='build')
    depends_on('netcdf-c')
    depends_on('netcdf-fortran')
    depends_on('parallel-netcdf')
    depends_on('mpi', when='+mpi')
    depends_on('cuda', when='+cuda')
    depends_on('cmake')
    depends_on('zlib')
    depends_on('bzip2')
 


    def install(self, spec, prefix):
        install_tree('ambertools_tmpdir', '.')
        shutil.rmtree(join_path(self.stage.source_path, 'ambertools_tmpdir'))
        subprocess.run(['./update_amber','--update'],stdout=subprocess.PIPE)
        compiler=spec.compiler.name
        if compiler == "gcc":
            ambercompiler = "GNU"
        elif compiler == "intel":
            ambercompiler = "INTEL"
        elif compiler == "pgi":
            ambercompiler = "PGI"
 
        args = []
        args.append('..')
        args.append('-DCMAKE_INSTALL_PREFIX='+prefix)
        args.append('-DCOMPILER='+ambercompiler)
        args.append('-DMPI=FALSE')
        args.append('-DCUDA=FALSE')
        args.append('-DINSTALL_TESTS=TRUE')
        args.append('-DDOWNLOAD_MINICONDA=TRUE')
        args.append('-DPnetCDF_C_LIBRARY='+join_path(spec['parallel-netcdf'].prefix,'lib','libpnetcdf.so'))
        args.append('-DPnetCDF_C_INCLUDE_DIR='+join_path(spec['parallel-netcdf'].prefix,'include'))
        args.append('-DNetCDF_INCLUDES='+join_path(spec['parallel-netcdf'].prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_F90='+join_path(spec['netcdf-fortran'].prefix,'lib','libnetcdff.so'))
        args.append('-DNetCDF_INCLUDES_F90='+join_path(spec['netcdf-fortran'].prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_C='+join_path(spec['netcdf-c'].prefix,'lib','libnetcdf.so'))
        args.append('-DNetCDF_INCLUDE_C='+join_path(spec['netcdf-c'].prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_C='+join_path(spec['netcdf-c'].prefix,'lib','libnetcdf.so'))
        args.append('-DNetCDF_INCLUDE_C='+join_path(spec['netcdf-c'].prefix,'include'))
        os.chdir('build')
        cmake(*args)
        make('install')
        for x,y in enumerate(args):
                if '-DDOWNLOAD_MINICONDA=TRUE' in y:
                    args.remove(y)
                    args.insert(x,'-DDOWNLOAD_MINICONDA=FALSE')
             
        args.append('-DBUILD_PYTHON=FALSE')
        if '+mpi' in spec:
            for x,y in enumerate(args):
                if 'DMPI' in y:
                    args.remove(y)
                    args.insert(x,'-DMPI=TRUE')
                    cmake(*args)
                    make('install')
        if '+cuda' in spec:
            for x,y in enumerate(args):
                if 'DMPI' in y:
                    args.remove(y)
                    args.insert(x,'-DMPI=FALSE')
                elif 'DCUDA' in y:
                    args.remove(y)
                    args.insert(x,'-DCUDA=TRUE')
            cmake(*args)
            make('install')
            if '+mpi' in spec:
                for x,y in enumerate(args):
                    if 'DMPI' in y:
                        args.remove(y)
                        args.insert(x,'-DMPI=TRUE')
                        cmake(*args)
                        make('install')

    def setup_run_environment(self, env):
        env.set('AMBER_PREFIX', self.prefix)
        env.set('AMBERHOME', self.prefix)
        env.prepend_path('PATH',join_path(self.prefix,'miniconda','bin'))
        file = glob.glob(join_path(self.prefix,'miniconda','lib','python*'))[0]
        env.prepend_path('PYTHONPATH',join_path(file,'site-packages'))
        file = glob.glob(join_path(self.prefix.lib,'python*'))[0]
        env.prepend_path('PYTHONPATH',join_path(file,'site-packages'))

