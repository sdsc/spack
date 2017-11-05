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


class RFactoextra(RPackage):
    """factoextra: Extract and Visualize the Results of Multivariate Data
    Analyses"""

    homepage = "http://www.sthda.com/english/rpkgs/factoextra"
    url      = "https://cran.r-project.org/src/contrib/factoextra_1.0.4.tar.gz"

    version('1.0.4', 'aa4c81ca610f17fdee0c9f3379e35429')

    depends_on('r@3.1.0:')
    depends_on('r-ggplot2@2.2.0:', type=('build', 'run'))
    depends_on('r-abind', type=('build', 'run'))
    # depends_on('r-cluster', type=('build', 'run'))
    depends_on('r-dendextend', type=('build', 'run'))
    depends_on('r-factominer', type=('build', 'run'))
    depends_on('r-ggpubr', type=('build', 'run'))
    depends_on('r-reshape2', type=('build', 'run'))
    depends_on('r-ggrepel', type=('build', 'run'))
    depends_on('r-tidyr', type=('build', 'run'))
