##############################################################################
# Copyright (c) 2013-2016, Lawrence Livermore National Security, LLC.
# Produced at the Lawrence Livermore National Laboratory.
#
# This file is part of Spack.
# Created by Todd Gamblin, tgamblin@llnl.gov, All rights reserved.
# LLNL-CODE-647188
#
# For details, see https://github.com/llnl/spack
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


class Fontconfig(AutotoolsPackage):
    """Fontconfig is a library for configuring/customizing font access"""
    homepage = "http://www.freedesktop.org/wiki/Software/fontconfig/"
    url      = "http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.3.tar.gz"

    version('2.12.3', 'aca0c734c1a38eb3ba12b2447dd90ab0')
    version('2.12.1', 'ce55e525c37147eee14cc2de6cc09f6c')
    version('2.11.1', 'e75e303b4f7756c2b16203a57ac87eba')

    depends_on('freetype')
    depends_on('gperf', type='build', when='@2.12.2:')
    depends_on('libxml2')
    depends_on('pkg-config', type='build')
    depends_on('font-util')

    def configure_args(self):
        font_path = join_path(self.spec['font-util'].prefix, 'share', 'fonts')

        return [
            '--enable-libxml2',
            '--disable-docs',
            '--with-default-fonts={0}'.format(font_path)
        ]

    @run_after('install')
    def system_fonts(self):
        # point configuration file to system-install fonts
        # gtk applications were failing to display text without this
        config_file = join_path(self.prefix, 'etc', 'fonts', 'fonts.conf')
        filter_file('<dir prefix="xdg">fonts</dir>',
                    '<dir prefix="xdg">fonts</dir><dir>/usr/share/fonts</dir>',
                    config_file)
