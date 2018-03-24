##############################################################################
# Copyright (c) 2013-2018, Lawrence Livermore National Security, LLC.
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

import llnl.util.filesystem as fs


def test_move_transaction_commit(tmpdir):

    fake_library = tmpdir.mkdir('lib').join('libfoo.so')
    fake_library.write('Just some fake content.')

    old_md5 = fs.hash_directory(str(tmpdir))

    with fs.replace_directory_transaction(str(tmpdir.join('lib'))):
        fake_library = tmpdir.mkdir('lib').join('libfoo.so')
        fake_library.write('Other content.')
        new_md5 = fs.hash_directory(str(tmpdir))

    assert old_md5 != fs.hash_directory(str(tmpdir))
    assert new_md5 == fs.hash_directory(str(tmpdir))


def test_move_transaction_rollback(tmpdir):

    fake_library = tmpdir.mkdir('lib').join('libfoo.so')
    fake_library.write('Just some fake content.')

    h = fs.hash_directory(str(tmpdir))

    try:
        with fs.replace_directory_transaction(str(tmpdir.join('lib'))):
            assert h != fs.hash_directory(str(tmpdir))
            fake_library = tmpdir.mkdir('lib').join('libfoo.so')
            fake_library.write('Other content.')
            raise RuntimeError('')
    except RuntimeError:
        pass

    assert h == fs.hash_directory(str(tmpdir))
