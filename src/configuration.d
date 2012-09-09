/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    sdb, a Simple D Builder
    Copyright (C) 2012 Dimitri 'skp' Sabadie <sabadie.dimitri@gmail.com> 

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

module configuration;

import std.algorithm : startsWith;
import std.array : array, splitter;
import std.file : FileException, isFile; 
import std.stdio : File, lines, writefln;
import std.string : strip;
import common;

final class CConfiguration {
    enum DEFAULT_FILE = ".sdb";

    private {
        alias void delegate(string[]) token_fun_t;
        token_fun_t[string] _tokenFunTbl;
        EBuildType _bt;
        ETargetType _tt;
        string[] _libDirs;
        string[] _libs;
        string[] _importDirs;
        string[] _srcDirs;
        string[] _testDirs;
        string _outName;
    }

    @property {
        EBuildType bt() const {
            return _bt;
        }

        ETargetType tt() const {
            return _tt;
        }

        auto lib_dirs() const {
            return _libDirs;
        }

        auto libs() const {
            return _libs;
        }

        auto import_dirs() const {
            return _importDirs;
        }

        auto src_dirs() const {
            return _srcDirs;
        }

        auto test_dirs() const {
            return _testDirs;
        }

        auto out_name() const {
            return _outName;
        }
    }

    this(string file) in {
        assert ( file !is null );
    } body {
        init_fun_();

        if (!file.isFile) {
            if (file == DEFAULT_FILE)
                throw new FileException(file, "unable to open file");
            load_(DEFAULT_FILE);
        } else {
            load_(file);
        }
    }

    private void default_() {
        _bt = EBuildType.DEBUG;
        _tt = ETargetType.EXEC;
        _srcDirs = [ "../src" ];
        _testDirs = [ "../test" ];
    }

    private void init_fun_() {
        _tokenFunTbl = [
            "BUILD"      : &build_,
            "TARGET"     : &target_,
            "LIB_DIR"    : &values_!"libDirs",
            "LIB"        : &values_!"libs",
            "IMPORT_DIR" : &values_!"importDirs",
            "SRC_DIR"    : &values_!"srcDirs",
            "TEST_DIR"   : &values_!"testDirs",
            "OUT_NAME"   : &values_!"outName"
        ];
    }

    private void load_(string file) {
        auto fh = File(file, "r");

        fh.isOpen; /* TODO: not critical but that just... sucks a lot */

        foreach (ulong i, string line; lines(fh)) {
            auto str = strip(line);
            auto tokens = array(splitter(str));

            if (tokens.length >= 2) {
                /* tokens[0] is the variable type, tokens[1..$] the values */
                auto varType = tokens[0];
                debug writefln("reading variable '%s'", varType);
                _tokenFunTbl[tokens[0]](tokens[1..$]);
            } else {
                writefln("incorrect line syntax (%d tokens): L%d: %s", tokens.length, i, str);
            }
        }

        check_dirs_();
    }

    private void check_dirs_() {
        void foreach_check_(string a)() {
            mixin("foreach (ref d; " ~ a ~ ")
                       d = check_file_prefix_(d);");
        }

        foreach_check_!"_libDirs"();
        foreach_check_!"_importDirs"();
        foreach_check_!"_srcDirs"();
        foreach_check_!"_testDirs"();
    }

    private string check_file_prefix_(string file) {
        if (startsWith(file, '.', '/', '~') == 0)
            file = "./" ~ file;
        return file;
    }

    private void build_(string[] values) {
        if (values.length == 1) {
            switch (values[0]) {
                case "debug" :
                    _bt = EBuildType.DEBUG;
                    break;

                case "release" :
                    _bt = EBuildType.RELEASE;
                    break;

                default :
                    writefln("warning: '%s' is not a correct build type", values[0]);
            }
        } 
    }

    private void target_(string[] values) {
        if (values.length == 1) {
            switch (values[0]) {
                case "exec" :
                    _tt = ETargetType.EXEC;
                    break;

                case "static" :
                    _tt = ETargetType.STATIC;
                    break;

                case "shared" :
                    _tt = ETargetType.SHARED;
                    break;

                default :
                    writefln("warning: '%s' is not a correct target type", values[0]);
            }
        }
    }

    /* TODO: this function is correct but the mixin is a little rough imho */
    private void values_(string token)(string[] values) {
        mixin("auto r = &_" ~ token ~ ";");
        static if (token == "outName")
            *r = values[0];
        else
            *r = values;
    }
}
