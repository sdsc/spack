# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Bamutil(MakefilePackage):
    """bamUtil is a repository that contains several programs
       that perform operations on SAM/BAM files. All of these programs
       are built into a single executable, bam.
    """

    homepage = "https://genome.sph.umich.edu/wiki/BamUtil"
    git = "https://github.com/statgen/bamUtil.git"
    url = "https://github.com/statgen/bamUtil/archive/refs/tags/v1.0.15.tar.gz"

    version('1.0.15', sha256='24ac4bdb81eded6e33f60dba85ec3d32ebdb06d42f75df775c2632bbfbd8cce9')
    version('1.0.14', sha256='f5ec8d5e98a3797742106c3413a4ab1622d8787e38b29b3df4cddb59d77efda5')

    depends_on('zlib', type=('build', 'link'))
    depends_on("git", type="build", when="@1.0.14:")

    parallel = False

    @when("@1.0.14:")
    def edit(self, spec, prefix):
        filter_file("git://", "https://", "Makefile.inc", string=True)

    @when("@1.0.14:")
    def build(self, spec, prefix):
        make("cloneLib")
        make()

    @property
    def install_targets(self):
        return ['install', 'INSTALLDIR={0}'.format(self.prefix.bin)]
