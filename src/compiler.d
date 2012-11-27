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
import std.array : join, replace, split;
import std.file : exists, SpanMode, SysTime, timeLastModified;
import std.process : system;
import std.stdio : writeln, writefln;
import std.string : chomp;
import std.conv : to;
import common;
import configuration;

enum ECompileState {
    COMPILED, /* module successfully compiled */
    ALREADY, /* module already compiled */
    FAIL /* module failed to compile */
}

final class CCompiler {
    alias typeof(this) that;
    
    /* FIXME: move that with a string import */
    enum SDB_CONFIG_DIR = chomp(import("conf_dir.dcfg"), dirSeparator) ~ dirSeparator;

    private {
        string _invocation;
        string _objSwitch;
        string _libDirDecl;
        string _libDecl;
        string _importDirDecl;
        string _outDecl;
        string _debugSwitch;
        string _releaseSwitch;
        string _execSwitch;
        string _staticSwitch;
        string _sharedSwitch;
    }
    
    /* TODO: rename to bt2str_ */
    /* Convert a EBuildType into a string. */
    private string bt2str_(EBuildType b) {
        string bt;

        final switch (b) {
            case EBuildType.DEBUG :
                bt = _debugSwitch;
                break;

            case EBuildType.RELEASE :
                bt = _releaseSwitch;
                break;
        }

        return bt;
    }

    /* Convert a ETargetType into a string. */
    private string tt2str_(ETargetType t) {
        string tt;

        final switch (t) {
            case ETargetType.EXEC :
                tt = _execSwitch;
                break;

            case ETargetType.STATIC :
                tt = _staticSwitch;
                break;

            case ETargetType.SHARED :
                tt = _sharedSwitch;
                break;
        }

        return tt;
    }

    /* compile the given file into an object file which path and name are given */
    ECompileState compile(string file, string obj, EBuildType buildtype, in string[] importDirs) {
        auto state = ECompileState.ALREADY;
        auto bt = bt2str_(buildtype);
        auto cmd = _invocation ~ ' '
            ~ _objSwitch ~ ' '
            ~ bt ~ ' '
            ~ (importDirs.length ? _importDirDecl ~ reduce!((string a, string b) => a ~ " " ~ _importDirDecl ~ b)(importDirs) ~ " " : "")
            ~ _outDecl;

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
    void link(string[] objs, string output, EBuildType buildtype, ETargetType targettype, in string[] libDirs, in string[] libs) {
        string objects = join(objs, " ");
        auto bt = bt2str_(buildtype);
        auto tt = tt2str_(targettype);
        auto cmd = _invocation ~ ' '
            ~ tt ~ ' '
            ~ bt ~ ' '
            ~ (libDirs.length ? _libDirDecl ~ reduce!((string a, string b) => a ~ " " ~ _libDirDecl ~ b)(libDirs) ~ " " : "")
            ~ (libs.length ? _libDecl ~ reduce!((string a, string b) => a ~ " " ~ _libDecl ~ b)(libs) ~ " " : "")
            ~ _outDecl ~ output ~ " ";

        debug writefln("-- %s%s", cmd, objects);
        system(cmd ~ objects);
    }
    
    /* load the compiler from disk */
    static that from_disk(string path) {
        if (!exists(path)) {
            /* TODO */
            throw new Exception("'" ~ path ~ "' doesn't exist");
        }
        
        auto cmp = new CCompiler;
        debug {
            auto fh = File(path, "r");
            char[] token;
            char[][] values;
            foreach (string line; lines(fh)) {
                auto splitted = split(strip(line), "=");
                if (splitted.length > 2) {
                    /* TODO */
                    throw new Exception("'" ~ line ~ "' is misformed");
                }
                cmp.set_param_(strip(splitted[0]), strip(splitted[1]));
            }
        } else {
            static assert (0, "need to use skp.lexi");
            /* auto raw = readText(path); */
        }
        
        return cmp;
    }   

    private void set_param_(string param, string value) {
        switch (param) {
            case "invocation" :
                _invocation = value;
                break;
                
            case "obj_switch" :
                _objSwitch = value;
                break;
                
            case "lib_dir_decl" :
                _libDirDecl = value;
                break;
            
            case "lib_decl" :
                _libDecl = value;
                break;
                
            case "import_dir_decl" :
                _importDirDecl = value;
                break;
            
            case "out_decl" :
                _outDecl = value;
                break;
            
            case "debug_switch" :
                _debugSwitch = value;
                break;
            
            case "release_switch" :
                _releaseSwitch = value;
                break;
            
            case "exec_switch" :
                _execSwitch = value;
                break;
            
            case "static_switch" :
                _staticSwitch = value;
                break;
            
            case "shared_switch" :
                _sharedSwitch = value;
                break;
            
            default :
                /* TODO */
                throw new Exception("'" ~ param ~ "' is an unkown compiler parameter");
        }
        
        debug writefln("-- setting compiler parameter '%s' to '%s'", param, value);
    }
}