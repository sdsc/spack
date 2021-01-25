# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

# ----------------------------------------------------------------------------
# If you submit this package back to Spack as a pull request,
# please first remove this boilerplate and all FIXME comments.
#
# This is a template package file for Spack.  We've put "FIXME"
# next to all the things you'll want to change. Once you've handled
# them, you can save this file and test your package like this:
#
#     spack install amber
#
# You can edit this file again by typing:
#
#     spack edit amber
#
# See the Spack documentation for more information on packaging.
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
    url      = "file://{0}/Amber20.tar.bz2".format(os.getcwd())


    version('20', sha256='a4c53639441c8cc85adee397933d07856cc4a723c82c6bea585cd76c197ead75')

    resources = [
        # [version amber, version ambertools , sha256sum]
        ('20', '20', 'b1e1f8f277c54e88abc9f590e788bbb2f7a49bcff5e8d8a6eacfaf332a4890f9'),
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
    depends_on('python@3.7.6%gcc@9.2.0')
    depends_on('mpi', when='+mpi')
    depends_on('cuda', when='+cuda')
    depends_on('intel-mkl')


    def install(self, spec, prefix):
#       with open('/tmp/o','w') as fp:
#            attrs = vars(spec)
#            print(', '.join("%s: %s" % item for item in attrs.items()),file=fp)
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
        args.append('-DPnetCDF_C_LIBRARY='+join_path(spec.get_dependency('parallel-netcdf').spec._prefix,'lib','libpnetcdf.so'))
        args.append('-DPnetCDF_C_INCLUDE_DIR='+join_path(spec.get_dependency('parallel-netcdf').spec._prefix,'include'))
        args.append('-DNetCDF_INCLUDES='+join_path(spec.get_dependency('parallel-netcdf').spec._prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_F90='+join_path(spec.get_dependency('netcdf-fortran').spec._prefix,'lib','libnetcdff.so'))
        args.append('-DNetCDF_INCLUDES_F90='+join_path(spec.get_dependency('netcdf-fortran').spec._prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_C='+join_path(spec.get_dependency('netcdf-c').spec._prefix,'lib','libnetcdf.so'))
        args.append('-DNetCDF_INCLUDE_C='+join_path(spec.get_dependency('netcdf-c').spec._prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_C='+join_path(spec.get_dependency('netcdf-c').spec._prefix,'lib','libnetcdf.so'))
        args.append('-DNetCDF_INCLUDE_C='+join_path(spec.get_dependency('netcdf-c').spec._prefix,'include'))
        args.append('-DFORCE_EXTERNAL_LIBS=mkl')
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
