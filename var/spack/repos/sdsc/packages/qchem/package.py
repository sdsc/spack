# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import spack.repo
import os.path


class Qchem(Package):

    homepage = "https://http://www.q-chem.com"
    url      = "file://{0}/qchem-5.3.tar.gz".format(os.getcwd())
 
 
    version('6.0', extension='.tar',sha256='98272a8f7ed7dab0f79991ac62b7d6f3d1e9b0e565509ae8adf1a4b1bc8a75e6')
    version('5.4', sha256='2e55b23aa66235c2fa94c281534907963d527a660f6b535703f8aac90bf263fe')
    version('5.3.2', sha256='b5de10207299281da5aea85d8b9cb4a2d349f77942ca10484d6f42b0d0d4a479')
    version('5.3', sha256='0647b5e25dc458c4c97d31a7f6a41773cfef06d277b599c4b9f88e8100904d31')
 
    depends_on('mvapich2')
 
    def url_for_version(self, version):
       if version < Version('6.0'):
           return "file://{0}/qc-{1}.tar.gz".format(os.getcwd(),version)
       else:
           newversion=str(version).replace(".","")
           return "file://{0}/qc{1}.tar".format(os.getcwd(),newversion)

    def install(self, spec, prefix):
       mkdirp(join_path(prefix,'.update'))
       copy(join_path(os.path.dirname(self.module.__file__),'qcinstall'+spec.version.string+'.sh'),join_path(prefix,'.update','qcinstall.sh'))
       copy(join_path(os.path.dirname(self.module.__file__),'qcinstall'+spec.version.string+'.sh'),'qcinstall.sh')
       for file in ['license.sh','liveupdate.sh','qcenv_csh' \
          ,'qcenv_sh','register.sh']:
           copy(join_path(os.path.dirname(self.module.__file__),file),join_path(prefix,'.update'))
       copy(join_path(os.path.dirname(self.module.__file__),'liveupdate_6.0.sh'),join_path(prefix,'.update'))
       copy('.update/update.list',join_path(prefix,'.update'))
       filter_file('ROLLPATH',prefix,'qcinstall.sh')
       print(Executable('sh')('qcinstall.sh',output=str))
 
    def setup_build_environment(self, env):
       env.set('QC', self.prefix)
       env.set('QCMPI', 'mpich')
       env.set('QCAUX', self.prefix.qcaux)
       env.set('QCSCRATCH','.')
       env.set('LM_LICENSE_FILE','40000@elprado.sdsc.edu:40200@elprado.sdsc.edu')
       env.prepend_path('PATH',self.prefix.bin)
 
    def setup_run_environment(self, env):
       env.set('QC', self.prefix)
       env.set('QCMPI', 'mpich')
       env.set('QCAUX', prefix.qcaux)
       env.set('QCSCRATCH','.')
       env.set('LM_LICENSE_FILE','40000@elprado.sdsc.edu:40200@elprado.sdsc.edu')
 
    @run_after('install')
    @on_package_attributes(run_tests=True)
 
    def test(self):
       with working_dir(join_path(self.prefix.samples,'mp2')):
           output=Executable('qchem')('-nt','16','mp2_freq.in',output=str)
           teststring='Frequency:      1666.61                4067.89                4220.58'
           if teststring in output:
               print('PASSED')
           else:
               print('FAILED')
