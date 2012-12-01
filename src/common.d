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

public import skp.log;
import std.array : replace;
import std.ascii : newline;
import std.file : isDir, isFile, exists;
import std.string : chomp, removechars, strip;
public import std.path : dirSeparator;

enum EBuildType  { DEBUG, RELEASE };
enum ETargetType { EXEC, STATIC, SHARED };

final class CAbortLoading : Exception {
    this() {
        super("");
    }
}

string normalize_path(string path) {
    string np = path;
    
    np = removechars(path, newline);
    np = strip(path);
    np = np.replace("/", dirSeparator);
    np = np.replace("\\", dirSeparator);
    return np;
}

string module_to_file(string m, string rootsrc) {
    /* a module has the form:
     *   foo.bar.test.final.math.matrix
     * the corresponding file is:
     *   $(ROOT_SRC)/foo/bar/test/final/math/matrix.d
     */
    string f = m;
    
    f = f.replace(".", dirSeparator);
    f ~= ".d";
    return normalize_path(rootsrc ~ dirSeparator ~ f);
}

string file_to_module(string f, string rootsrc) {
    string m = normalize_path(f);
    m.length -= 2; /* popout the .d suffix */
    m = m[rootsrc.length+1 .. $]; /* popout the root prefix */
    m = m.replace(dirSeparator, ".");
    return m;
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

/* Checks if the path is a file */
bool is_file(string path) {
    /* first thing to do, check if the path exists */
    if (!path.exists)
        return false;

    /* then, verify it's really a file */
    try {
        if (!path.isFile)
            return false;
    } catch (const Exception e) {
        return false;
    }

    return true;
}

/* Checks if the path is a directory */
bool is_dir(string path) {
    /* first thing to do, check if the path exists */
    if (!path.exists)
        return false;

    /* then, verify it's really a directory */
    try {
        if (!path.isDir)
            return false;
    } catch (const Exception e) {
        return false;
    }

    return true;
}
