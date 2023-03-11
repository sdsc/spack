# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

import glob
from spack import *


class PyBxPython(PythonPackage):
    """The bx-python project is a python library and associated set of scripts
    to allow for rapid implementation of genome scale analyses."""

    homepage = "https://github.com/bxlab/bx-python"
    pypi = "bx-python/bx-python-0.8.8.tar.gz"

    version('0.8.8', sha256='ad0808ab19c007e8beebadc31827e0d7560ac0e935f1100fb8cc93607400bb47')
    version('0.7.4',
            sha256='1066d1e56d062d0661f23c19942eb757bd7ab7cb8bc7d89a72fdc3931c995cb4',
            url="https://github.com/bxlab/bx-python/archive/v0.7.4.tar.gz")

    depends_on('python@2.4:2.7', type=('build', 'run'), when='@:0.7')
    depends_on('python@2.7:2.8,3.5:', type=('build', 'run'), when='@0.8:')
    depends_on('py-setuptools', type='build')
    depends_on('py-python-lzo', type=('build', 'run'), when='@:0.7')
    depends_on('py-cython', type='build', when='@0.8:')
    depends_on('py-numpy', type=('build', 'run'))
    depends_on('py-six', type=('build', 'run'), when='@0.8:')

    @run_after('install')
    @on_package_attributes(run_tests=True)

    def test(self):
        python_path=glob.glob(join_path(self.prefix,'lib','python*','site-packages'))
        output=Executable('python')('-c','from bx import binned_array_tests;print(binned_array_tests.setup())',output=str)
        teststring='bx.binned_array.BinnedArray object'
        with open('/tmp/py-bx-python.output','w') as fp:
            if teststring in output:
                print('PASSED',file=fp)
            else:
                print('FAILED',file=fp)
