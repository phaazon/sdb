module sdb;

import std.algorithm : countUntil, reduce, startsWith;
import std.array : array, join, replace, splitter;
import std.ascii : whitespace;
import std.file : dirEntries, FileException, isDir, isFile, SpanMode, SysTime, timeLastModified;
import std.process : shell;
import std.stdio : File, lines, writeln, writefln;
import std.string : chomp, strip;


int main(string[] args) {
    return dispatch_args(args);
}

int dispatch_args(string[] args) {
    auto conf = new configuration(".sdb");

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
                auto comp = new compiler(conf);
                comp.compile(true);
                break;

            case "clean" :
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

void build(configuration conf) {
    writefln("building %s", conf.out_name);
    auto comp = new compiler(conf);
    comp.compile(false);
    comp.link();
}


/*
void test(string[] ts = null) {
    writefln("testing %s", conf.out_name);
    if (ts is null) {
        foreach (t; ts) {
 */


enum build_type  { DEBUG, RELEASE };
enum target_type { EXEC, STATIC, SHARED };

final class configuration {
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

        writefln("reading configuration from file '" ~ file ~ "'");
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

final class compiler {
    version(DigitalMars) {
        enum compiler_str   = "dmd -w -wi ";
        enum object_str     = "-c ";
        enum lib_dir_str    = "-L-L";
        enum lib_str        = "-L-l";
        enum import_dir_str = "-I";
        enum out_str        = "-of";
    }

    private configuration _conf;

    this(configuration conf) {
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

    void compile(bool test) {
        string bt = bt_();
        auto importDirs = _conf.import_dirs;
        auto cmd = compiler_str
            ~ object_str
            ~ bt ~ " "
            ~ (importDirs.length ? import_dir_str ~ reduce!("a ~ \" " ~ import_dir_str ~ "\"~ b")(importDirs) ~ " " : "")
            ~ out_str;

        foreach (string path; test ? _conf.test_dirs : _conf.src_dirs) {
            try {
                path.isDir;
            } catch (FileException e) {
                writefln("warning: %s", e.msg);
                continue; /* FIXME: a bit dirty imho */
            } 

            auto files = array(dirEntries(path, "*.d", SpanMode.depth));
            auto filesNb = files.length;
            writefln("%d files to compile", filesNb);
            foreach (int i, string file; files) {
                auto m = module_from_file_(file);
                if (timeLastModified(file) >= timeLastModified(m, SysTime.min)) {
                    writefln("--> [%4d%% | %s ]", cast(int)(((i+1)*100/filesNb)), m);
                    auto r = shell(cmd ~ m ~ " " ~ file ~ ".o");
                    debug writeln(cmd ~ m ~ " " ~ file);
                    if (r.length)
                        writeln(r ~ '\n');
                }
            }
        }
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
        foreach (string obj; files)
            objects ~= obj ~ " ";
        auto cmd = link_string_(_conf.out_name);
        debug writeln(cmd ~ objects);
        auto r = shell(cmd ~ objects);
        if (r.length)
            writeln(r ~ '\n');
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

    void test(string[] ts = null) {
        if (ts is null) {
            writeln("testing all the application");
            foreach (path; _conf.test_dirs) {
                auto files = array(dirEntries(path, "*.d", SpanMode.depth));
                auto filesNb = files.length;
                writefln("%d files to test", filesNb);
                foreach (int i, string file; files) {
                    auto m = module_from_file_(file);
                    if (m.isFile) {
                        writefln("--> [%4d%% | %s ]", cast(int)(((i+1)*100/filesNb)), m);
                        shell(m);
                    }
                }
            }
        } else {
        }
    }
}
