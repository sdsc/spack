# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
# ----------------------------------------------------------------------------

from spack import *
import os
import subprocess
import shutil


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
        ('22', '22', '1571d4e0f7d45b2a71dce5999fa875aea8c90ee219eb218d7916bf30ea229121'),
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
    depends_on('boost')
    depends_on('python')
    depends_on('mpi', when='+mpi')
    depends_on('cuda', when='+cuda')
    depends_on('cmake')


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
        args.append('-DDOWNLOAD_MINICONDA=FALSE')
        args.append('-DPYTHON_EXECUTABLE=python3')
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
