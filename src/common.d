/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   sdb, the Simple D Builder
   Copyright (C) 2012 Dimitri 'skp' Sabadie <dimitri.sabadie@gmail.com> 

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

module common;

/* This module gathers all the fucking common stuff. */

import std.array : replace;

enum EBuildType  { DEBUG, RELEASE };
enum ETargetType { EXEC, STATIC, SHARED };

final class CAbortLoading : Exception {
    this() {
        super("");
    }
}

string module_to_file(string m, string rootsrc) {
    /* a module has the form:
     *   foo.bar.test.final.math.matrix
     * the corresponding file is:
     *   $(ROOT_SRC)/foo/bar/test/final/math/matrix.d
     */

    m = m.replace(".", "/");
    m ~= ".d";
    return rootsrc ~ '/' ~ m;
}
