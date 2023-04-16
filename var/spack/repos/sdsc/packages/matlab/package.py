# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import os
import subprocess


class Matlab(Package):
    """MATLAB (MATrix LABoratory) is a multi-paradigm numerical computing
    environment and fourth-generation programming language. A proprietary
    programming language developed by MathWorks, MATLAB allows matrix
    manipulations, plotting of functions and data, implementation of
    algorithms, creation of user interfaces, and interfacing with programs
    written in other languages, including C, C++, C#, Java, Fortran and Python.

    Note: MATLAB is licensed software. You will need to create an account on
    the MathWorks homepage and download MATLAB yourself. Spack will search your
    current directory for the download file. Alternatively, add this file to a
    mirror so that Spack can find it. For instructions on how to set up a
    mirror, see http://spack.readthedocs.io/en/latest/mirrors.html"""

    homepage = "https://www.mathworks.com/products/matlab.html"
    manual_download = True

    version('2022b', sha256='b2627de2275404f9ba5be19578c0864b9d9568bdc353b12c74ac76e88d4d3fc3')
    version('2021b', sha256='c801e9ca72fff51f83dc6cef4bb35a5dc346d657aef652d079132d3a19514c14')
    version('2021a', sha256='c1810a00820eaec10fbc8c22ad8ec2504e95a73dead35069874ccbdd6b35381b')
    version('2020b', sha256='7e113bcb62a2d3ff50eb19e945062450c9ba34f58840b4f44c8dd023c72fe0a4')
    version('2020a', sha256='c65c4e5122c1ca7b1f8467feb8cd6e0d4765c232322a1288747352a5e9e8e331')

    variant(
        'mode',
        default='interactive',
        values=('interactive', 'silent', 'automated'),
        description='Installation mode (interactive, silent, or automated)'
    )

    variant(
        'key',
        default='<installation-key-here>',
        values=lambda x: True,  # Anything goes as a key
        description='The file installation key to use'
    )
    variant(
        'licensepath',
        default='<path to licensefile>',
        values=lambda x: True,
        description='The license file path'
    )

    # Licensing
    license_required = True
    license_comment  = '#'
    license_files    = ['licenses/network.lic']
    license_vars     = ['LM_LICENSE_FILE']
    license_url      = 'https://www.mathworks.com/help/install/index.html'

    extendable = True
    args=[]

    def url_for_version(self, version):
        return "file://{0}/matlab-{1}.tar.gz".format(os.getcwd(), version)

    def install(self, spec, prefix):
        if spec.version < Version('2021b'):
           subprocess.run(['./install',
               '-destinationFolder',
               prefix,
               '-mode',
               spec.variants['mode'].value,
               '-fileInstallationKey',
               spec.variants['key'].value,
               '-licensePath',
               spec.variants['licensepath'].value,
               '-agreeToLicense',
                'yes',
               '-outputFile',
                '/tmp/matlab.log',
               '-lmgrFiles',
               'false',
               '-lmgrService',
               'false'])
        else:
             copy(join_path(os.path.dirname(self.module.__file__)
           ,'installer_input.txt'),'.')
             filter_file('destinationFolder=','destinationFolder='+prefix,'installer_input.txt')
             filter_file('fileInstallationKey=','fileInstallationKey='+spec.variants['key'].value,'installer_input.txt')
             filter_file('licensePath=','licensePath='+spec.variants['licensepath'].value,'installer_input.txt')
             subprocess.run(['./install','-inputFile','installer_input.txt'])
