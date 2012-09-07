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

module sdb;

import std.algorithm : countUntil, reduce, startsWith;
import std.array : array, join, replace, splitter;
import std.ascii : whitespace;
import std.file : dirEntries, FileException, isDir, isFile, mkdir, remove, SpanMode, SysTime, timeLastModified;
import std.process : system;
import std.stdio : File, lines, writeln, writefln;
import std.string : chomp, strip;

int main(string[] args) {
    writeln(
"sdb  Copyright (C) 2012  Dimitri 'skp' Sabadie <sabadie.dimitri@gmail.com>
This program comes with ABSOLUTELY NO WARRANTY; for details type `warranty'.
This is free software, and you are welcome to redistribute it
under certain conditions; type `conditions' for details.\n");

    return dispatch_args(args);
}

int dispatch_args(string[] args) {
    CConfiguration conf;
   
    if (args.length == 2) {
        if (args[1] == "warranty") {
            writeln(
"  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.");
            return 0;
        } else if (args[1] == "conditions") {
            writeln("See the COPYING file for more details.");
            return 0;
        }
    }

    try {
    conf = new CConfiguration(".sdb");
    } catch (Exception e) {
        writeln("no .sdb configuration file found here");
        return 1;
    }

    if (args.length == 1) {
        build(conf);
        return 0;
    }

    foreach (a; args[1 .. $]) {
        switch (a) {
            case "build" :
                build(conf);
                break;

            case "btest" :
                auto outName = conf.out_name;
                writefln("building %s tests", outName ~ (outName[$-1] == 's' ? "'" : "'s"));
                auto comp = new CCompiler(conf);
                comp.compile(true);
                break;

            case "clean" :
                clean(conf);
                break;

            case "install" :
                break;

            case "uninstall" :
                break;

            default :
                writefln("usage: %s [build|test|clean]; '%s' is incorrect", args[0], a);
        }
    }

    return 0;
}

void build(CConfiguration conf) {
    writefln("building %s", conf.out_name);
    auto comp = new CCompiler(conf);
    if (comp.build(false))
        comp.link();
}

/*
void test(string[] ts = null) {
    writefln("testing %s", conf.out_name);
    if (ts is null) {
        foreach (t; ts) {
 */

void clean(CConfiguration conf) {
    /* removing the objects */
    auto objects = array(dirEntries(".", "*.o", SpanMode.depth));
    foreach (string o; objects)
        remove(o);

    /* removing the out */
    try {
        remove(conf.out_name);
    } catch (Exception e) {
    }
}

enum build_type  { DEBUG, RELEASE };
enum target_type { EXEC, STATIC, SHARED };

final class CConfiguration {
    enum DEFAULT_FILE = ".sdb";

    private {
        alias void delegate(string[]) token_fun_t;
        token_fun_t[string] _tokenFunTbl;
        build_type _bt;
        target_type _tt;
        string[] _libDirs;
        string[] _libs;
        string[] _importDirs;
        string[] _srcDirs;
        string[] _testDirs;
        string _outName;
    }

    @property {
        build_type bt() const {
            return _bt;
        }

        target_type tt() const {
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
        _bt = build_type.DEBUG;
        _tt = target_type.EXEC;
    }

    private void init_fun_() {
        _tokenFunTbl = [
            "BUILD" : &build_,
            "TARGET" : &target_,
            "LIB_DIR" : &values_!"libDirs",
            "LIB" : &values_!"libs",
            "IMPORT_DIR" : &values_!"importDirs",
            "SRC_DIR" : &values_!"srcDirs",
            "TEST_DIR" : &values_!"testDirs",
            "OUT_NAME" : &values_!"outName"
        ];
    }

    private void load_(string file) {
        auto fh = File(file, "r");

        if (!fh.isOpen)
            throw new FileException(file, "file is not opened");

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
                    _bt = build_type.DEBUG;
                    break;

                case "release" :
                    _bt = build_type.RELEASE;
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
                    _tt = target_type.EXEC;
                    break;

                case "static" :
                    _tt = target_type.STATIC;
                    break;

                case "shared" :
                    _tt = target_type.SHARED;
                    break;

                default :
                    writefln("warning: '%s' is not a correct target type", values[0]);
            }
        }
    }

    private void values_(string token)(string[] values) {
        mixin("auto r = &_" ~ token ~ ";");
        static if (token == "outName")
            *r = values[0];
        else
            *r = values;
    }
}

final class CCompiler {
    version(DigitalMars) {
        enum compiler_str   = "dmd -w -wi -unittest -property ";
        enum object_str     = "-c ";
        enum lib_dir_str    = "-L-L";
        enum lib_str        = "-L-l";
        enum import_dir_str = "-I";
        enum out_str        = "-of";
    }

    private CConfiguration _conf;

    this(CConfiguration conf) {
        _conf = conf;
    }

    private string bt_() {
        string bt;

        final switch (_conf.bt) {
            case build_type.DEBUG :
                bt = "-debug -g";
                break;

            case build_type.RELEASE :
                bt = "-release -O";
                break;
        }

        return bt;
    }

    bool build(bool test) {
        /* check if the .obj directory exists */
        try {
            ".obj".isDir;
        } catch (FileException e) {
            /* let's create it */
            mkdir(".obj");
        }

        /* then compile the files */
        return compile(test);
    }

    bool compile(bool test) {
        bool compiled = true;
        string bt = bt_();
        auto importDirs = _conf.import_dirs;
        auto cmd = compiler_str
            ~ object_str
            ~ bt ~ " "
            ~ (importDirs.length ? import_dir_str ~ reduce!("a ~ \" " ~ import_dir_str ~ "\"~ b")(importDirs) ~ " " : "")
            ~ out_str ~ ".obj/";

        foreach (string path; test ? _conf.test_dirs : _conf.src_dirs) {
            try {
                path.isDir;
            } catch (FileException e) {
                writefln("warning: %s", e.msg);
                continue; /* FIXME: a bit dirty imho */
            } 

            auto files = array(dirEntries(path, "*.d", SpanMode.depth));
            auto filesNb = files.length;
            writefln("%d file%s to compile", filesNb, (filesNb > 1 ? "s" : ""));
            foreach (int i, string file; files) {
                auto m = module_from_file_(file);
                auto obj = m ~ ".o";
                if (timeLastModified(file) >= timeLastModified(obj, SysTime.min)) {
                    writefln("--> [%4d%% | %s ]", cast(int)(((i+1)*100/filesNb)), m);
                    auto r = system(cmd ~ obj ~ " " ~ file);
                    debug writeln(cmd ~ obj ~ " " ~ file);
                    if (r != 0)
                        compiled = false;
                }
            }
        }

        return compiled;
    }

    private string module_from_file_(string file) in {
        assert ( file !is null );
    } body {
        auto startIndex = countUntil!"a != '.' && a != '/'"(file);
        auto m = chomp(file[startIndex .. $], "/");
        m = replace(m, "/", ".");
        return m[0 .. $-2];
    }

    void link() {
        writefln("Linking %s...", _conf.out_name);
        auto files = array(dirEntries(".", "*.o", SpanMode.depth));
        string objects;

        if (files.length == 0)
            return;
        foreach (string obj; files)
            objects ~= obj ~ " ";
        auto cmd = link_string_(_conf.out_name);
        debug writeln(cmd ~ objects);
        auto r = system(cmd ~ objects);
    }

    private string link_string_(string outName) {
        string bt = bt_();
        string tt;
        final switch (_conf.tt) {
            case target_type.EXEC :
                tt = "";
                break;

            case target_type.STATIC :
                tt = "-lib";
                break;

            case target_type.SHARED :
                tt = "-lib -shared";
                break;
        }
        auto libDirs = _conf.lib_dirs;
        auto libs = _conf.libs;
        auto cmd = compiler_str
            ~ tt ~ " "
            ~ bt ~ " "
            ~ (libDirs.length ? lib_dir_str ~ reduce!("a ~ \" " ~ lib_dir_str ~ "\"~ b")(libDirs) ~ " " : "")
            ~ (libs.length ? lib_str ~ reduce!("a ~ \" " ~ lib_str ~ "\"~ b")(libs) ~ " " : "")
            ~ out_str ~ outName ~ " ";
        return cmd;
    }

    void test() {
        writeln("testing all the application");
        foreach (path; _conf.test_dirs) {
            auto files = array(dirEntries(path, "*.d", SpanMode.depth));
            auto filesNb = files.length;
            writefln("%d files to test", filesNb);
            foreach (int i, string file; files) {
                writefln("--> [%4d%% | %s ]", cast(int)(((i+1)*100/filesNb)), file);
            }
        }
    }
}
