# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

import os

from spack import *
import llnl.util.tty as tty


class Bamtools(CMakePackage):
    """C++ API & command-line toolkit for working with BAM data."""

    homepage = "https://github.com/pezmaster31/bamtools"
    url      = "https://github.com/pezmaster31/bamtools/archive/v2.4.0.tar.gz"

    version('2.5.1', sha256='4abd76cbe1ca89d51abc26bf43a92359e5677f34a8258b901a01f38c897873fc')
    version('2.5.0', sha256='85e02e04998a67cbda7ab68cdab36cee133db024e814b34e06bb617b627caf9c')
    version('2.4.1', sha256='933a0c1a83c88c1dac8078c0c0e82f6794c75cb927265399404bc2cc2611204b')
    version('2.4.0', sha256='f1fe82b8871719e0fb9ed7be73885f5d0815dd5c7277ee33bd8f67ace961e13e')
    version('2.3.0', sha256='288046e6d5d41afdc5fce8608c5641cf2b8e670644587c1315b90bbe92f039af')
    version('2.2.3', sha256='92ddef44801a1f8f01ce1a397f83e0f8b5e1ae8ad92c620f2dafaaf8d54cf178')

    depends_on('zlib', type='link')

    def cmake_args(self):
        args = []
        rpath = self.rpath
        rpath.append(os.path.join(self.prefix.lib, "bamtools"))
        args.append("-DCMAKE_INSTALL_RPATH=%s" % ':'.join(rpath))
        return args

    @run_after('install')
    @on_package_attributes(run_tests=True)

    def test(self):
        mkdirp(join_path(prefix,'examples'))
        copy(join_path(os.path.dirname(self.module.__file__),'test.cc'),join_path(self.prefix,'examples'))
        copy(join_path(os.path.dirname(self.module.__file__),'test.bam'),join_path(self.prefix,'examples'))
        with working_dir(join_path(self.prefix,'examples')):
            Executable(spack_cxx)( '-o','bamtest','-I','../include/bamtools',
               'test.cc','-L','../lib64','-lbamtools','-lz',error=str)
            output=Executable('./bamtest')('test.bam',output=str,error=str)
            teststring='Qualities ;44999;499<8<8<<<8<<><<<<><7<;<<<>><<'
            with open('/tmp/bamtools.output','w') as fp:
                if teststring in output:
                    print('PASSED',file=fp)
                else:
                    print('FAILED',file=fp)
