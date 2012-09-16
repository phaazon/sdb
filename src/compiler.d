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

module compiler;

import std.algorithm : countUntil, reduce;
import std.array : array, replace;
import std.file : dirEntries, FileException, isDir, mkdir, SpanMode, SysTime, timeLastModified;
import std.process : system;
import std.stdio : writeln, writefln;
import std.string : chomp; 
import common;
import configuration;

/* TODO: need to refactor all this class if we want to upgrade the project with brand new killa features! */
final class CCompiler {
    /* TODO: need to rename all this enum string in order to make them more comprehensible */
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
            case EBuildType.DEBUG :
                bt = "-debug -g";
                break;

            case EBuildType.RELEASE :
                bt = "-release -O";
                break;
        }

        return bt;
    }

    bool build(bool test) {
        auto outdir = (test ? ".objt" : ".obj");
        debug writefln("out dir is: %s", outdir);

        /* check if the directory exists */
        try {
            outdir.isDir;
        } catch (FileException e) {
            mkdir(outdir);
        }

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
            ~ out_str ~ (test ? ".objt/" : ".obj/");

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
                    debug writeln(cmd ~ obj ~ " " ~ file);
                    auto r = system(cmd ~ obj ~ " " ~ file);
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

    void link(bool test) {
        writefln("Linking %s...", _conf.out_name ~ (test ? "\'s tests" : ""));
        auto objdir = test ? ".objt" : ".obj";
        auto files = array(dirEntries(objdir, "*.o", SpanMode.depth));
        string objects;

        if (files.length == 0)
            return;
        if (test) {
            /* we have to link program one by one */
            foreach (string obj; files) {
                auto cmd = link_string_(".test/" ~ module_from_file_(obj));
                debug writeln(cmd ~ obj);
                auto r = system(cmd ~ obj);
            }
        } else {
            foreach (string obj; files)
                objects ~= obj ~ " ";
            auto cmd = link_string_(_conf.out_name);
            debug writeln(cmd ~ objects);
            auto r = system(cmd ~ objects);
        }
    }

    private string link_string_(string outName) {
        string bt = bt_();
        string tt;
        final switch (_conf.tt) {
            case ETargetType.EXEC :
                tt = "";
                break;

            case ETargetType.STATIC :
                tt = "-lib";
                break;

            case ETargetType.SHARED :
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
