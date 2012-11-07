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

string file_to_module(string f, string rootsrc) {
	f.length -= 2; /* popout the .d suffix */
	f = f[rootsrc.length+1 .. $]; /* popout the root prefix */
	f = f.replace("/", ".");
	return f;
}

/* A linear search function. */
bool any(alias __Pred, __Range)(__Range r) {
    foreach (a; r) {
        static if (is(typeof(__Pred) : string)) {
            mixin("return (" ~ __Pred ~ ");");
        } else {
            if (__Pred(a))
                return true;
        }
    }
    
    return false;
}
