# Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Libffi(AutotoolsPackage):
    """The libffi library provides a portable, high level programming
    interface to various calling conventions. This allows a programmer
    to call any function specified by a call interface description at
    run time."""
    homepage = "https://sourceware.org/libffi/"

    version('3.2.1', sha256='d06ebb8e1d9a22d19e38d63fdb83954253f39bedc5d46232a05645685722ca37',
            url="https://www.mirrorservice.org/sites/sourceware.org/pub/libffi/libffi-3.2.1.tar.gz")
    # version('3.1', md5='f5898b29bbfd70502831a212d9249d10',url =
    # "ftp://sourceware.org/pub/libffi/libffi-3.1.tar.gz") # Has a bug
    # $(lib64) instead of ${lib64} in libffi.pc

    @property
    def headers(self):
        # The headers are probably in self.prefix.lib but we search everywhere
        return find_headers('ffi', self.prefix, recursive=True)
