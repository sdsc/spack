# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
from spack import *
import os


class PerlTermReadlineGnu(PerlPackage):
    """Perl extension for the GNU Readline/History Library."""

    homepage = "https://metacpan.org/pod/Term::ReadLine::Gnu"
    url      = "https://cpan.metacpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.36.tar.gz"

    version('1.45', sha256='9f4f7abbc69ea58ab7f24992d47f7391bb4aed6fb701fedaeb1a9f1cdc7fab8a')
    version('1.36', sha256='9a08f7a4013c9b865541c10dbba1210779eb9128b961250b746d26702bab6925')

    depends_on('readline')
#   depends_on('ncurses')

    def configure_args(self):
        args=[]
        p = self.spec['readline'].prefix.include
        args.append('--includedir={0}'.format(p))
#       p = join_path(self.spec['ncurses'].prefix.lib,'libncurses.so')
#       args.append('LIBS={0}'.format(p))
        return(args)
