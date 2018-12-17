##############################################################################
# Copyright (c) 2013-2017, Lawrence Livermore National Security, LLC.
# Produced at the Lawrence Livermore National Laboratory.
#
# This file is part of Spack.
# Created by Todd Gamblin, tgamblin@llnl.gov, All rights reserved.
# LLNL-CODE-647188
#
# For details, see https://github.com/spack/spack
# Please also see the NOTICE and LICENSE files for our notice and the LGPL.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License (as
# published by the Free Software Foundation) version 2.1, February 1999.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the IMPLIED WARRANTY OF
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the terms and
# conditions of the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
##############################################################################
from spack import *
import os


class Mark(Package):
    """Program MARK, developed and maintained by Gary White (Colorado State
    University) is the most flexible, widely used application currently
    available for parameter estimation using data from marked individuals.

    You will need to download the package yourself, unzip, rename it
    following the guide in http://www.phidot.org/software/mark/rmark/linux/
    Step(1). Spack will search your current directory for the download file.
    Alternatively, add this file to a mirror so that Spack can find it.
    For instructions on how to set up a mirror, see
    http://spack.readthedocs.io/en/latest/mirrors.html"""

    homepage = "http://www.phidot.org/software/mark/index.html"

    version('1.0', '64f2fb0837c38d6e41c7546b25627146', expand=False)

    def url_for_version(self, version):
        return "file://{0}/mark".format(os.getcwd())

    def install(self, spec, prefix):
        mkdir(prefix.bin)
        install('mark', prefix.bin)

        chmod = which('chmod')
        chmod('+x', prefix.bin.mark)
