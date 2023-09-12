# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import os
import glob
import shutil
import re

class Gamess(Package):

    homepage = "https://www.msg.chem.iastate.edu/gamess/"
#   url      = "file:///state/partition1/gamess-2019.06.tar.gz"
    url      = "http://forge.sdsc.edu/triton/gamess/src/gamess/gamess-2019.06.tar.gz"

    version('2021.09', sha256='9afe67a8ffad93d03b19caa9e5af8240c2c8c20031e2a72e0e0d9ad7da3bec03')
    version('2020.09', sha256='d3a069ecba638e8bae83f9f86f1fb1b0bf4742f1ff57b59bb64835ae97749412')
    version('2019.06', sha256='9515b5901ac44117153a17aa0df159097a374db7cc8b7aabae2d67a4fb9c37e5')
    
    variant('mathlib',default='openblas',values=('openblas','mkl','atlas','none'))
    variant('libxc', default=False)

    depends_on('mpi')
    depends_on('openblas', when='mathlib=openblas')
    depends_on('intel-mkl', when='mathlib=mkl')
    depends_on('atlas', when='mathlib=atlas')

    patch('compddi2.patch',when='@2021.09')
    patch('compddi.patch',when='@:2019.06')
    patch('comp.patch',when='@:2019.06')
    patch('compall.patch',when='@:2019.06')
    patch('lked.patch',when='@:2019.06')
    patch('rungms.patch')


    def url_for_version(self, version):
        return "file://{0}/gamess-{1}.tar.gz".format(os.getcwd(), version)

    def setup_run_environment(self, env):
        env.prepend_path('PATH', self.prefix)
        env.set('GMSPATH',self.prefix)


    def install(self, spec, prefix):
        cwd=self.stage.source_path
        filter_file('ROLL_PATHGAMESS',prefix,'rungms')
        if 'mvapich2' in spec['mpi'].name:
           mpiflavor='mvapich2'
        elif 'openmpi' in spec['mpi'].name:
           mpiflavor='openmpi'
        elif 'intel-mpi' in spec['mpi'].name:
           mpiflavor='impi'
        filter_file('ROLL_MPITYPE',mpiflavor,'rungms')
        mpipath = spec['mpi'].prefix
        filter_file('ROLLMPI',mpipath,'rungms')

        install_info = '#!/bin/csh -f' + '\n' \
                   + 'setenv GMS_PATH '  + cwd + '\n' \
                   + 'setenv GMS_BUILD_DIR  ' + cwd + '\n' \
                   + 'setenv GMS_TARGET         linux64' + '\n'
        if 'intel-mpi' in spec['mpi'].name:
            mpicmd = Executable(join_path(mpipath,'compilers_and_libraries','linux','mpi','intel64','bin','mpif77'))('-show',output=str,error=str)
        else:
            mpicmd = Executable(join_path(mpipath,'bin','mpif77'))('-show',output=str,error=str)
        mpilibs = re.sub(r'^.*-L','-L',mpicmd)
        if spec.version <= Version('2019.06'):
           filter_file('ROLLMPILIBS',mpilibs,'lked')
        fc = os.path.split(spack_fc)[1]
        if spec.compiler.name == "intel":
           fortver=spec.compiler.version.string.split('.')[0]
           install_info += 'setenv GMS_IFORT_VERNO ' + fortver + '\n'
           install_info += 'setenv GMS_FPE_FLAGS -fpe0' + '\n'
        elif spec.compiler.name == "gcc":
           verstring=spec.compiler.version.string.split('.')
           fortver=verstring[0]+'.'+verstring[1]
           install_info += 'setenv GMS_GFORTRAN_VERNO ' + fortver + '\n'
           install_info += 'setenv GMS_FPE_FLAGS -ffpe-trap=invalid,zero,overflow' + '\n'
        install_info += 'setenv GMS_FORTRAN     ' + fc + '\n' \
                     +  'setenv GMS_MSUCC false      ' + '\n' \
                     +  'setenv GMS_LIBCCHEM false ' + '\n' \
                     +  'setenv GMS_MATHLIB   ' + spec.variants['mathlib'].value + '\n'
        if 'mathlib=mkl' in spec:
           mlib=spec['intel-mkl'].prefix + '/lib/intel64'
           mklver=spec['intel-mkl'].version.string.split('.')[0]
           install_info += 'setenv GMS_MKL_VERNO   ' + mklver + '\n'
        elif 'mathlib=openblas' in spec:
           mlib=spec['openblas'].prefix + '/lib'
        elif 'mathlib=atlas' in spec:
           mlib=spec['atlas'].prefix + '/lib'
                        
        install_info += 'setenv GMS_MATHLIB_PATH   ' + mlib + '\n' \
                     +  'setenv GMS_DDI_COMM   mpi'  + '\n' \
                     +  'setenv GMS_MPI_LIB    '   + mpiflavor + '\n' \
                     +  'setenv GMS_MPI_PATH   '  + mpipath + '\n'
        if mpiflavor ==  'mvapich2':
           verstring=spec['mpi'].version.string.split('.')
           mpiver=verstring[0]+'.'+verstring[1]
           install_info += 'setenv GMS_MVAPICH2_VERNO   ' + mpiver + '\n'

        install_info += 'setenv GMS_PHI            false' + '\n' \
                        + 'setenv GMS_OPENMP         false' + '\n' \
                        + 'setenv GMS_SHMTYPE        posix' + '\n'

        if '+libxc' in spec:
           install_info += 'setenv GMS_LIBXC true' + '\n'
        else:
           install_info += 'setenv GMS_LIBXC false' + '\n'
        install_info += 'setenv GMS_MDI false' + '\n'
        install_info += 'setenv TINKER false' + '\n'
        install_info += 'setenv GMS_VM2 false' + '\n'
        install_info += 'setenv  XMVB  false' + '\n'
        install_info += 'setenv  NEO  false' + '\n'
        install_info += 'setenv  NBO  false' + '\n'

 

        with open(join_path(cwd,'install.info'),'w') as file:
           print(install_info,file=file)

        if spec.version <= Version('2019.06'):
           filter_file(r'^.UNX','    ','tools/actvte.f')
           copy('tools/actvte.code','tools/actvte.f')
           with working_dir('tools', create=False):
              Executable(fc)('-o','actvte.x','actvte.f')
        with working_dir('ddi', create=False):
           Executable('./compddi')()

        Executable('./compall')()
        Executable('./lked')()
        for filename in [ 'gamess.00.x', 'runall', 'rungms','install.info','gms-files.csh']:
           copy(filename,prefix)
        shutil.copytree('auxdata',join_path(prefix,'auxdata'))
        shutil.copytree('tests',join_path(prefix,'tests'))
        docfiles=glob.glob('*.DOC')
        for filename in docfiles:
           copy(filename,prefix)

    def setup_run_environment(self, env):
        env.set('GAMESSHOME',self.prefix)
        env.set('GMSPATH',self.prefix)
        env.prepend_path('PATH',self.prefix)

    def setup_build_environment(self, env):
        if 'intel-mpi' in self.spec['mpi'].name and self.spec.compiler.name == "intel":
            env.set('I_MPI_F77','ifort')
