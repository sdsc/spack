# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import glob


class Blat(Package):
    """BLAT (BLAST-like alignment tool) is a pairwise sequence
       alignment algorithm."""

    homepage = "https://genome.ucsc.edu/FAQ/FAQblat.html"
    url      = "https://users.soe.ucsc.edu/~kent/src/blatSrc35.zip"

    version('35', sha256='06d9bcf114ec4a4b21fef0540a0532556b6602322a5a2b33f159dc939ae53620')

    depends_on('libpng')

    def setup_build_environment(self, env):
        env.set('MACHTYPE', 'x86_64')

    def install(self, spec, prefix):
        filter_file('CC=.*', 'CC={0}'.format(spack_cc), 'inc/common.mk')
        mkdirp(prefix.bin)
        make("BINDIR=%s" % prefix.bin)

    @run_after('install')
    @on_package_attributes(run_tests=True)

    def test(self):
        mkdirp(join_path(self.prefix,'test'))
        files=glob.glob(join_path('blat','test','intron50k','*.fa'))
        files.extend(glob.glob(join_path('blat','test','intron50k',
             'expected','*.psl')))
        for file in files:
            copy(file,join_path(self.prefix,'test'))
       
        with working_dir(self.prefix):
            Executable(join_path('bin','blat'))('-verbose=0', join_path('test','target.fa'),join_path('test','query.fa'),
                 'blat.out','-minScore=190')
            output = Executable('cmp')(join_path('test','test1.psl'), 'blat.out',output=str,error=str)
            with open('/tmp/blat.output','w') as fp:
                if not output:
                    print('PASSED',file=fp)
                else:
                    print('FAILED',file=fp)
