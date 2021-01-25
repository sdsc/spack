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
#     spack install cp2k
#
# You can edit this file again by typing:
#
#     spack edit cp2k
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *
import os
import subprocess
import re


class Cp2k(Package,CudaPackage):
    """FIXME: Put a proper description of your package here."""

    # FIXME: Add a proper url for your package's homepage here.
    homepage = "https://www.example.com"
    url      = "https://github.com/cp2k/cp2k/releases/download/v7.1.0/cp2k-7.1.tar.bz2"

    # FIXME: Add a list of GitHub accounts to
    # notify when the package is updated.
    # maintainers = ['github_user1', 'github_user2']

    version('7.1', sha256='ccd711a09a426145440e666310dd01cc5772ab103493c4ae6a3470898cd0addb')
    resource(name='libint',url='https://github.com/cp2k/libint-cp2k/releases/download/v2.6.0/libint-v2.6.0-cp2k-lmax-7.tgz',
        sha256='3bcdcc55e1dbafe38a785d4af171df8e300bb8b7775894b57186cdf35807c334',
        version='2.6.0',
        destination='',placement='libint')
    resource(name='libxc',url='http://www.tddft.org/programs/libxc/down.php?file=4.2.3/libxc-4.2.3.tar.gz',
        sha256='02e49e9ba7d21d18df17e9e57eae861e6ce05e65e966e1e832475aa09e344256',
        version='4.2.3',
        destination='',placement='libxc')
    resource(name='libxsmm',url='https://github.com/hfp/libxsmm/archive/1.15.tar.gz',
        sha256='499e5adfbf90cd3673309243c2b56b237d54f86db2437e1ac06c8746b55ab91c',
        version='1.15',
        destination='',placement='libxsmm')

    variant('cuda', description='Build cuda execuatables',
            default=False)
    depends_on('mpi')
    depends_on('intel-mkl')
    depends_on('libfabric',when='^intel-mpi')
    depends_on('cuda',when='+cuda')
    depends_on('py-numpy',when='+cuda')
    
    def setup_environment(self, spack_env, run_env):
        spack_env.set('CC',spack_cc)
        spack_env.set('CXX',spack_cxx)
        spack_env.set('FC',spack_fc)

    def install(self, spec, prefix):
         copy(join_path(os.path.dirname(self.module.__file__),'Linux-x86-64-intel.psmp'),'arch')
         copy(join_path(os.path.dirname(self.module.__file__),'Linux-x86-64-gnu.psmp'),'arch')
         copy(join_path(os.path.dirname(self.module.__file__),'Linux-x86-64-intel.psmp'),'arch')
         copy(join_path(os.path.dirname(self.module.__file__),'Linux-x86-64-gnu.psmp'),'arch')
         copy(join_path(os.path.dirname(self.module.__file__),'configure-get.sh'),'libint')


         if 'mvapich2' in spec['mpi'].name or 'intel-mpi' in spec['mpi'].name:
              intelmpitype='intelmpi'
         elif 'openmpi' in spec['mpi'].name:
              intelmpitype='openmpi'

         if self.spec.compiler.name == "intel":
              compilername='intel'
              arch='Linux-x86-64-intel'
         elif self.spec.compiler.name == "gcc":
              compilername='gnu'
              arch='Linux-x86-64-gnu'
         if '+cuda' in spec:
              makefile=arch+'.psmp'
         else:
              makefile=arch+'.psmp'
         mkllib = join_path(spec.get_dependency('intel-mkl').spec._prefix,'mkl')
         filter_file('MKL_ROOT',mkllib,join_path('arch',makefile))
         filter_file('INTELMPITYPE',intelmpitype,join_path('arch',makefile))
         filter_file('LIBINTPATH',join_path(self.stage.source_path,'libint'),join_path('arch',makefile))
         filter_file('LIBXCPATH',join_path(self.stage.source_path,'libxc'),join_path('arch',makefile))
         filter_file('LIBXSMMPATH',join_path(self.stage.source_path,'libxsmm'),join_path('arch',makefile))
         with working_dir('libint'):
              subprocess.run(['sh','configure-get.sh','libint'])
              if self.spec.compiler.name == "intel":
                   subprocess.run(['patch','configure-libint-hsw.sh',join_path(os.path.dirname(self.module.__file__),'configure-libint-hsw.sh.patch')])
                   subprocess.run(['sh','./configure-libint-hsw.sh'])
              elif self.spec.compiler.name == "gcc":
                   subprocess.run(['patch','configure-libint-hsw-gnu.sh',join_path(os.path.dirname(self.module.__file__),'configure-libint-hsw-gnu.sh.patch')])
                   subprocess.run(['sh','./configure-libint-hsw-gnu.sh'])
              make()
              make('install','-j1')
         if self.spec.compiler.name == "intel":
              os.environ['CXXFLAGS'] = '-O2 -xHost' 
              os.environ['CCLAGS'] =  '-O2 -xHost'
              os.environ['FCFLAGS'] =  '-O2 -xHost'
         elif self.spec.compiler.name == "gcc":
              os.environ['CXXFLAGS'] = '-O2 -march=native'
              os.environ['CCLAGS'] = '-O2 -march=native'
              os.environ['FCFLAGS'] = '-O2 -march=native'
         with working_dir('libxc'):
              configure('--prefix='+join_path(os.getcwd(),'..','libxc'),'--enable-fortran','--enable-shared')
              make()
              make('install')
         with working_dir('libxsmm'):
              make('PREFIX='+join_path(os.getcwd(),'..','libxsmm'),'install','ARCH='+arch,'VERSION=psmp')
         mkdirp(join_path(prefix,'test'))
         mkdirp(join_path(prefix,'lib'))
         mkdirp(join_path(prefix,'data'))
         mkdirp(prefix.bin)
         if '+cuda' in spec:
              cudadefs='-D__ACC -D__DBCSR_ACC -D__PW_CUDA'
              filter_file('CUDADEFS',cudadefs,join_path('arch',makefile))
              cudalibs='-L'+join_path(spec.get_dependency('cuda').spec._prefix,'lib64')+' -lcuda -lcudart -lcublas -lcufft -lnvrtc'
              filter_file('CUDALIBS',cudalibs,join_path('arch',makefile))
              nvccpath=join_path(spec.get_dependency('cuda').spec._prefix,'bin','nvcc')
              
              filter_file('NVCCPATH',nvccpath,join_path('arch',makefile))
              filter_file('MKLROOT',mkllib,join_path('arch',makefile))

              cuda_arch = int(spec.variants['cuda_arch'].value[0])
              if cuda_arch >= 35 and cuda_arch < 37:
                   os.environ['GPUVER']='K40'
              elif cuda_arch >= 37 and cuda_arch < 60:
                   os.environ['GPUVER']='K80'
              elif cuda_arch >= 60 and cuda_arch < 70:
                   os.environ['GPUVER']='P100'
              elif cuda_arch >= 70 and cuda_arch < 75:
                   os.environ['GPUVER']='V100'

              make('ARCH='+arch,'VERSION=psmp','realclean')
              make('CC='+self.spec['mpi'].mpicc,'CXX='+self.spec['mpi'].mpicxx,'FC='+self.spec['mpi'].mpifc, 'ARCH='+arch,'VERSION=psmp')
              with working_dir(join_path('exe','Linux-x86-64-'+compilername)):
                   os.remove('cp2k_shell.psmp')
                   for file in os.listdir('.'):
                        newname = re.sub(r'\.psmp','.'+str(cuda_arch)+'.psmp',file)
                        os.rename(file,newname)
                        install(newname,prefix.bin)
              with working_dir(prefix.bin):
                   os.symlink('cp2k.'+str(cuda_arch)+'.psmp','cp2k_shell.'+str(cuda_arch)+'.psmp')
              install(join_path(os.path.dirname(self.module.__file__),'cp2k.cuda.psmp'),prefix.bin)
              with working_dir(prefix.bin):
                   filter_file('CUDABIN',join_path(spec.get_dependency('cuda').spec._prefix,'extras','demo_suite'),'cp2k.cuda.psmp')
                   filter_file('PKGROOT',prefix,'cp2k.cuda.psmp')
         else:
              filter_file('CUDADEFS',' ',join_path('arch',makefile))
              filter_file('CUDALIBS','',join_path('arch',makefile))
              filter_file('NVCCPATH','',join_path('arch',makefile))
              make('CC='+self.spec['mpi'].mpicc,'CXX='+self.spec['mpi'].mpicxx,'FC='+self.spec['mpi'].mpifc, 'ARCH='+arch,'VERSION=psmp')
              with working_dir(join_path('exe','Linux-x86-64-'+compilername)):
                   os.remove('cp2k_shell.psmp')
                   for file in os.listdir('.'):
                        install(file,prefix.bin)
              with working_dir(prefix.bin):
                   os.symlink('cp2k.psmp','cp2k_shell.psmp')
         install_tree(join_path('tests','MC','regtest'),join_path(prefix,'test'))
         install_tree('data',join_path(prefix,'data'))
         install_tree(join_path('libxc','lib'),join_path(prefix,'lib'))
