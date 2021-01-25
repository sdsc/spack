# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import os
import subprocess
import glob
import shutil


class Gaussian(Package,CudaPackage):
    """Gaussian  is a computer program for computational chemistry"""

    homepage = "http://www.gaussian.com/"
    url = "file://{0}/gaussian-16.C.01.tar.gz".format(os.getcwd())
    manual_download = True

    version('16.C.01', sha256='a75c81aceee257d62ac0e21e9c7797f776b0e31aab3fb7e9e15257cacd1e30a9')
    variant('cuda',default=True,description='compile for gpus')
    depends_on('cuda',when='+cuda')
    depends_on('pgi@18.10')
    patch('gau-hname.patch')
    patch('bldg16.patch')


    def install(self, spec, prefix):
        mkdirp(join_path(prefix,'g16'))
        copy(join_path(os.path.dirname(self.module.__file__),'buildg16.in'),'.')
        os.rename('buildg16.in','buildg16')
        if '+cuda' in spec:
            filter_file('CUDABUILD','volta','buildg16')
        else:
            filter_file('CUDABUILD','','buildg16')
        with working_dir('g16'):
            subprocess.run([join_path('..','buildg16'),self.stage.source_path])
            gaufiles=glob.glob('gau-*') + glob.glob('bsd/gau-*')
            for file in gaufiles:
                 install(file,join_path(prefix,'g16'))
            install('g16',join_path(prefix,'g16'))
            mkdirp('basis')
            install_tree('basis',join_path(prefix,'g16','basis'))
            mkdirp('tests')
            install_tree('tests',join_path(prefix,'g16','tests'))
            subprocess.run(['find','.','-maxdepth','1','-type','f','-executable','-exec','cp','{}',join_path(prefix,'g16'),';'])

    def setup_run_environment(self, env):
        env.set('g16root', self.prefix)
        env.set('GAUSSIANHOME', self.prefix)
        env.set('GAUSS_EXEDIR', join_path(self.prefix,'g16'))
        env.prepend_path('PATH', join_path(self.prefix,'g16'))
        env.set('G16_BASIS', join_path(self.prefix,'g16','basis'))

    def setup_build_environment(self, env):
        env.prepend_path('PATH',join_path(self.spec.get_dependency('pgi').spec._prefix,'linux86-64','18.10','bin'))
        env.prepend_path('PATH','/bin')
        env.prepend_path('PATH','/home/jpg/gcc/4.8.5/gcc/bin')
        env.prepend_path('LD_LIBRARY_PATH','/home/jpg/gcc/4.8.5/gmp/lib')
        env.prepend_path('LD_LIBRARY_PATH','/home/jpg/gcc/4.8.5/mpfr/lib')
        env.prepend_path('LD_LIBRARY_PATH','/home/jpg/gcc/4.8.5/mpc/lib')
        env.prepend_path('LD_LIBRARY_PATH','/home/jpg/gcc/4.8.5/gcc/lib64')
        env.prepend_path('LD_LIBRARY_PATH','/usr/lib64')
