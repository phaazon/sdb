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

/* This modules gathers compilers' abstraction. */

import std.algorithm : reduce;
import std.array : join, replace;
import std.file : SpanMode, SysTime, timeLastModified;
import std.process : system;
import std.stdio : writeln, writefln;
import common;
import configuration;

enum ECompileState {
    COMPILED, /* module successfully compiled */
    ALREADY, /* module already compiled */
    FAIL /* module failed to compile */
}

final class CCompiler {
    /* Note: to add the use of a new compiler, just fill in, copy and paste the below version block
       under the others:

       else version (YourCompilerVersionTag) {
           enum COMPILER_CMD    = "the command to use to call the compiler";
           enum OBJECT_FLAG     = "the argument to pass to your compiler to generate an object file";
           enum LIB_DIR_DECL    = "the argument to pass to your compiler to specify a single lib directory";
           enum LIB_DECL        = "the argument to pass to your compiler to specify a lib to use";
           enum IMPORT_DECL     = "the argument to pass to your compiler to specify an import directory";
           enum OUT_DECL        = "the argument to pass to your compiler to specify the name of the output";
           enum BT_DEBUG        = "the arguments to pass to your compiler for debug";
           enum BT_RELEASE      = "the arguments to pass to your compiler for release";
           enum TT_EXEC         = "the arguments to pass to your compiler to generate an executable";
           enum TT_STATIC       = "the arguments to pass to your compiler to generate a static library";
           enum TT_SHARED       = "the arguments to pass to your compiler to generate a dynamic library";
       }
     */

    version (DigitalMars) {
        enum COMPILER_CMD    = "dmd -w -wi -unittest -property ";
        enum OBJECT_FLAG     = "-c ";
        enum LIB_DIR_DECL    = "-L-L";
        enum LIB_DECL        = "-L-l";
        enum IMPORT_DIR_DECL = "-I";
        enum OUT_DECL        = "-of";
        enum BT_DEBUG        = "-debug -g ";
        enum BT_RELEASE      = "-release -O ";
        enum TT_EXEC         = " ";
        enum TT_STATIC       = "-lib ";
        enum TT_SHARED       = "-lib -shared ";
    } else {
        static assert (0, "unsupported compiler, please be free to contribute to add a support for it");
    }

    /* TODO: rename to bt2str_ */
    /* Convert a EBuildType into a string. */
    private string bt_(EBuildType b) {
        string bt;

        final switch (b) {
            case EBuildType.DEBUG :
                bt = BT_DEBUG;
                break;

            case EBuildType.RELEASE :
                bt = BT_RELEASE;
                break;
        }

        return bt;
    }

    /* Convert a ETargetType into a string. */
    private string tt2str_(ETargetType t) {
        string tt;

        final switch (t) {
            case ETargetType.EXEC :
                tt = TT_EXEC;
                break;

            case ETargetType.STATIC :
                tt = TT_STATIC;
                break;

            case ETargetType.SHARED :
                tt = TT_SHARED;
                break;
        }

        return tt;
    }

    /* compile the given file into an object file which path and name are given */
    ECompileState compile(string file, string obj, EBuildType buildtype, const(string)[] importDirs) {
        auto state = ECompileState.ALREADY;
        auto bt = bt_(buildtype);
        auto cmd = COMPILER_CMD
            ~ OBJECT_FLAG
            ~ bt
            ~ (importDirs.length ? IMPORT_DIR_DECL ~ reduce!("a ~ \" " ~ IMPORT_DIR_DECL ~ "\"~ b")(importDirs) ~ " " : "")
            ~ OUT_DECL;

        if (timeLastModified(file) >= timeLastModified(obj, SysTime.min)) {
            state = ECompileState.COMPILED;
            debug writefln("-- %s%s %s", cmd, obj, file);
            auto r = system(cmd ~ obj ~ " " ~ file);
            if (r != 0)
                state = ECompileState.FAIL;
        }

        return state;
    }

    /* Link objects into a target output. */
    void link(string[] objs, string output, EBuildType buildtype, ETargetType targettype, const(string)[] libDirs, const(string)[] libs) {
        string objects = join(objs, " ");
        auto bt = bt_(buildtype);
        auto tt = tt2str_(targettype);
        auto cmd = COMPILER_CMD
            ~ tt
            ~ bt
            ~ (libDirs.length ? LIB_DIR_DECL ~ reduce!("a ~ \" " ~ LIB_DIR_DECL ~ "\"~ b")(libDirs) ~ " " : "")
            ~ (libs.length ? LIB_DECL ~ reduce!("a ~ \" " ~ LIB_DECL ~ "\"~ b")(libs) ~ " " : "")
            ~ OUT_DECL ~ output ~ " ";

        debug writefln("-- %s%s", cmd, objects);
        system(cmd ~ objects);
    }
}
