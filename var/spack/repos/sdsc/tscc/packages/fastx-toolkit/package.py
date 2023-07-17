# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class FastxToolkit(AutotoolsPackage):
    """The FASTX-Toolkit is a collection of command line tools for
       Short-Reads FASTA/FASTQ files preprocessing."""

    homepage = "http://hannonlab.cshl.edu/fastx_toolkit/"
    url      = "https://github.com/agordon/fastx_toolkit/releases/download/0.0.14/fastx_toolkit-0.0.14.tar.bz2"

    version('0.0.14', sha256='9e1f00c4c9f286be59ac0e07ddb7504f3b6433c93c5c7941d6e3208306ff5806')

    depends_on('libgtextutils')

    # patch implicit fallthrough
    patch("pr-22.patch")
    # fix error [-Werror,-Wpragma-pack]
    patch('fix_pragma_pack.patch', when='%fj')

    @run_after('install')
    @on_package_attributes(run_tests=True)

    def test(self):
        copy(join_path('src','seqalign_test','seqalign_test'),self.prefix.bin)
        output=Executable(join_path(prefix.bin,'seqalign_test'))(output=str,error=str)
        teststring='A(AGGTTT)CCC'
        with open('/tmp/fastx-toolkit','w') as fp:
            if teststring in output:
                print('PASSED',file=fp)
            else:
                print('FAILED',file=fp)
