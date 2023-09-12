# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import os
import glob


class Gaussian(Package,CudaPackage):
    """Gaussian  is a computer program for computational chemistry"""

    homepage = "http://www.gaussian.com/"

    manual_download = True

    version('16-C.02b', sha256='df1e4e9c5429637e13c88659ae3ccb1c9cfdc344045ff26c3ab86a1077bf93c8')
    version('16-C.02', sha256='590e4e27521dd6a11bb80a3f30c5beba0f143bfdd9ddb4016580d9d2e2041d0a',preferred=True)
    version('16-C.01', sha256='a75c81aceee257d62ac0e21e9c7797f776b0e31aab3fb7e9e15257cacd1e30a9')
    variant('cuda',default=False,description='compile for gpus')
    variant('binary',default=False,description='precompiled binaries')
    depends_on('cuda',when='+cuda')
    patch('gau-hname.patch',level=1,when='~binary')
    patch('bldg16.patch',level=1,when='~binary')
    

    def url_for_version(self, version):
        return "file://{0}/gaussian-{1}.tar.gz".format(os.getcwd(), version)

    def install(self, spec, prefix):
        mkdirp(prefix.g16)
        if '~binary' in spec:
            copy(join_path(os.path.dirname(self.module.__file__),'buildg16.in'),'.')
            os.rename('buildg16.in','buildg16')
            if '+cuda' in spec:
                filter_file('CUDABUILD','volta','buildg16')
            else:
                filter_file('CUDABUILD','','buildg16')
            with working_dir('g16'):
                Executable(join_path('..','buildg16'))(self.stage.source_path)
                gaufiles=glob.glob('gau-*') + glob.glob('bsd/gau-*')
                for file in gaufiles:
                    install(file,join_path(prefix.g16))
                install('g16',join_path(prefix.g16))
                mkdirp('basis')
                install_tree('basis',join_path(prefix.g16,'basis'))
                mkdirp('tests')
                install_tree('tests',join_path(prefix.g16,'tests'))
                Executable('find')('.','-maxdepth','1','-type','f','-executable','-exec','cp','{}',prefix.g16,';')
        else:
            install_tree('.',prefix.g16)
        if '+cuda' in spec:
            copy(join_path(os.path.dirname(self.module.__file__),'getcpusets'),prefix.g16)

    def setup_run_environment(self, env):
        env.set('g16root', self.prefix)
        env.set('GAUSSIANHOME', self.prefix)
        env.set('GAUSS_EXEDIR', join_path(self.prefix.g16))
        env.prepend_path('PATH', join_path(self.prefix,'g16'))
        env.set('G16_BASIS', join_path(self.prefix.g16,'basis'))

    def setup_build_environment(self, env):
        env.set('PGROUPD_LICENSE_FILE','40000@elprado.sdsc.edu:40200@elprado.sdsc.edu')
        pgi_prefix = ancestor(self.compiler.cc, 2)
        env.prepend_path('PATH',join_path(pgi_prefix,'linux86-64','18.10','bin'))
        env.prepend_path('PATH','/bin')
        env.prepend_path('LD_LIBRARY_PATH','/usr/lib64')
        env.set('g16root', self.prefix)
        env.set('GAUSSIANHOME', self.prefix)
        env.set('GAUSS_EXEDIR', self.prefix.g16)
        env.prepend_path('PATH', self.prefix.g16)
        env.prepend_path('PATH', join_path(self.prefix.g16,'bsd'))
        env.set('G16_BASIS', join_path(self.prefix.g16,'basis'))

    @run_after('install')
    def exe_permissions(self):
        if '+cuda' in self.spec:
            Executable('chmod')('0750',join_path(prefix.g16,'getcpusets'))

#   @run_after('install')

#   def test(self):
#       def replacetestfilename(name):
#           if len(name) == 1:
#               return("000" + name)
#           elif len(name) == 2:
#               return("00" + name)
#           elif len(name) == 3:
#               return("0" + name)
#           elif len(name) ==  4:
#               return(name)
#       tests=['1', '28', '94', '155', '194', '296', '302']
#       fp=open('/tmp/gaussian.output','w')
#       with working_dir(join_path(prefix.g16,'tests')): 
#           with open('/tmp/gaussian.output','w') as fp:
#               for test in tests:
#                   testname=replacetestfilename(test)
#                   Executable('rm')('-f',join_path('amd64','test'+testname+'.log'))
#                   if '+cuda' in self.spec:
#                        with working_dir('com'):
#                            copy('test'+testname+'.com','test'+testname+'.tmp.com')                      
#                            Executable('getcpusets')('tmp')                      
#                            Executable('cat')('tmp.out','test'+testname+'.tmp.com','>','test'+testname+'.com')
#                   Executable('./submit.csh')(test,test)
#                   output=Executable('cat')(join_path('amd64','test'+testname+'.log'),output=str,error=str)
#                   print("TEST " + test,file=fp)
#                   teststring='Normal termination'
#                   if teststring in output:
#                        print('PASSED',file=fp)
#                   else:
#                        print('FAILED',file=fp)
#                   if '+cuda' in self.spec:
#                        with working_dir('com'):
#                            copy('test'+testname+'.tmp.com','test'+testname+'.com')
