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
#     spack install qchem
#
# You can edit this file again by typing:
#
#     spack edit qchem
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *
import spack.repo
import os.path
import subprocess


class Qchem(Package):

    homepage = "https://http://www.q-chem.com"
    url      = "file://{0}/qchem-5.3.tar.gz".format(os.getcwd())


    version('5.3', sha256='0647b5e25dc458c4c97d31a7f6a41773cfef06d277b599c4b9f88e8100904d31')

    variant('mpi', default=True, description='Activate MPI support')
    depends_on('mpi', when='+mpi')

    def install(self, spec, prefix):
       mkdirp(join_path(prefix,'.update'))
       file_path=os.path.split(spack.repo.path.filename_for_package_name(self.name))[0]
       copy(join_path(file_path,'qcinstall.sh'),self.stage.source_path)
       for file in ['qcinstall.sh','license.sh','liveupdate.sh','qcenv_csh' \
          ,'qcenv_sh','register.sh']:
          copy(join_path(file_path,file),join_path(prefix,'.update'))
       copy('.update/update.list',join_path(prefix,'.update'))
       filter_file('ROLLPATH',prefix,'qcinstall.sh')
       subprocess.run(['sh','qcinstall.sh'])

    def setup_run_environment(self, env):
        env.set('QC', self.prefix)
        env.set('QCMPI', 'mpich')
        env.set('QCAUX', join_path(prefix,'qcaux'))
        env.set('QCSCRATCH','.')
