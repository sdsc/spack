# Copyright 2013-2018 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class PyBreakseq2(PythonPackage):
    """nucleotide-resolution analysis of structural variants"""

    homepage = "http://bioinform.github.io/breakseq2/"
    url      = "https://github.com/bioinform/breakseq2/archive/2.2.tar.gz"

    version('2.2', '6fd5a103c2781717b0b1d0efcbdc17e7')

    depends_on('py-setuptools', type='build')
    depends_on('py-biopython@1.65', type=('build', 'run'))
    depends_on('py-cython', type='build')
    depends_on('py-pysam@0.7.7', type=('build', 'run'))
    depends_on('bwa', type='run')
    depends_on('samtools', type='run')
