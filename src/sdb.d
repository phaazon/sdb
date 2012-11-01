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

/* TODO: all this module has to be refactored and cleaned */

module sdb;

import std.array : array;
import std.file : dirEntries, FileException, remove, rmdir, SpanMode;
import std.process : system;
import std.stdio : writeln, writefln;
import configuration;
import compiler;
import common;
import modules_loader;

enum VERSION = "0.8-103012";

int main(string[] args) {
    return dispatch_args(args);
}

void vers() {
    writeln(
            "sdb " ~ VERSION ~ "
            Copyright (C) 2012  Dimitri 'skp' Sabadie <dimitri.sabadie@gmail.com>
            This program comes with ABSOLUTELY NO WARRANTY; for details type `warranty'.
            This is free software, and you are welcome to redistribute it
            under certain conditions; type `conditions' for details.");
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
        } else if (args[1] == "version") {
            vers();
            return 0;
        }
    }

    try {
        conf = new CConfiguration(".sdb");
    } catch (const CAbortLoading e) {
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

            case "scan" :
                break;

            case "btest" :
                /*
                   auto outName = conf.out_name;
                   writefln("building %s tests", outName ~ (outName[$-1] == 's' ? "'" : "'s"));
                   auto comp = new CCompiler(conf);
                   if (comp.compile(true))
                   comp.link(true);
                 */
                break;

            case "test" :
                /*
                   test(conf);
                 */
                break;

            case "clean" :
                /*
                   clean(conf);
                 */
                break;

            default :
                writefln("usage: %s [build|scan|btest|test|clean] [CONFIG_FILE]; '%s' is incorrect", args[0], a);
        }
    }

    return 0;
}

void build(CConfiguration conf) {
    writefln("building %s", conf.out_name);
    auto comp = new CCompiler;

    /* test : scan */
    auto mloader = new CModulesLoader(conf);
    mloader.scan(conf.entry_point);
}

void test(CConfiguration conf) {
    writefln("testing %s", conf.out_name);

    auto programs = array(dirEntries(".test", SpanMode.depth));
    auto filesNb = programs.length;
    foreach (int i, string t; programs) {
        auto r = system(t);
        writefln("--> [%4d%% | %s ] %s", cast(int)(((i+1)*100/filesNb)), t, (r ? "FAIL" : "OK"));
    }
}

void clean(CConfiguration conf) {
    void remove_dir(string name) {
        try {
            auto files = array(dirEntries(name, SpanMode.depth));
            foreach (f; files)
                remove(f);
            rmdir(name);
        } catch (FileException e) {
        }
    }

    /* removing the application objects */
    remove_dir(".obj");
    /* removing the test objects */
    remove_dir(".objt");
    /* removing the test programs */
    remove_dir(".test");

    /* removing the out */
    try {
        remove(conf.out_name);
    } catch (FileException e) {
    }
}
