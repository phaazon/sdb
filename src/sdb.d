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
import std.file : exists, dirEntries, isDir, FileException, remove, rmdir, SpanMode;
import std.process : system;
import std.stdio : writeln, writef, writefln, lines;
import configuration;
import compiler;
import common;
import modules_loader;

enum VERSION = "0.9.1-112612";
enum DEFAULT_CONF_PATH = ".sdb";

int main(string[] args) {
    try {
        return dispatch_args(args);
    } catch (const Exception e) {
        writefln("error: %s", e.msg);
        return 1;
    }
}

void print_vers() {
    writeln(
"sdb " ~ VERSION ~ "
Copyright (C) 2012  Dimitri 'skp' Sabadie <dimitri.sabadie@gmail.com>
This program comes with ABSOLUTELY NO WARRANTY; for details type `warranty'.
This is free software, and you are welcome to redistribute it
under certain conditions; type `conditions' for details.");
}

void print_warranty() {
    writeln(
"  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.");
}

int dispatch_args(string[] args) {
    auto argc = args.length;
    
    if (argc == 1) {
        /* invoked with no arguments, simply print the version */
        print_vers();
        return 0;
    } else if (argc == 2) {
        /* one argument passed */
        switch (args[1]) {
            case "warranty" :
                print_warranty();
                return 0;
            case "conditions" :
                writeln("See the COPYING file for more details.");
                return 0;
            case "version" :
                print_vers();
                return 0;
            default :
                break;
        }
    }

    /* if we go here we have more than one argument */
    string compiler;
    string confPath = DEFAULT_CONF_PATH;
    bool doBuild = false;
    bool doClean = false;
    for (auto i = 1; i < argc; ++i) {
        switch(args[i]) {
            /* select the compiler to use */
            case "with" :
                if (i < argc-1)
                    compiler = args[i+1];
                i += 2;
                break;
            /* build */
            case "build" :
                doBuild = true;
                break;
            case "clean" :
                doClean = true;
                break;
            default :
                writefln("'%s' is incorrect", args[i]);
                usage(args[0]);
                return 1;
        }
    }
    
    auto conf = new CConfiguration(confPath);
    if (doClean) {
        /* clean all sdb output traces */
        debug writeln("-- cleaning...");
        clean(conf);
    }
    
    if (!compiler.empty) {
        /* user passed a compiler, so let's determine what to do with */
        if (!doClean || doBuild) {
            debug writeln("-- building...");
            build(conf, conf.entry_point, conf.out_name, compiler);
        }
    }

    return 0;
}

void usage(string progName) {
    writeln(
"usage:\n\t" ~
progName ~ " [build] with <compiler>\n\t" ~
progName ~ " clean\n\t" ~
progName ~ " build test with <compiler>");
}

void build(CConfiguration conf, string m, string output, string compiler) {
    writefln("building %s with %s", m, compiler);
    auto comp = CCompiler.from_disk(CCompiler.SDB_CONFIG_DIR ~ chomp(compiler) ~ ".conf"); /* FIXME */
	auto mfpath = scan(conf, m);
    
    version ( Posix ) {
        enum OBJ_EXT = ".o";
    } else version ( Windows ) {
        enum OBJ_EXT = ".obj";
    } else {
        static assert (0, "unsupported operating system");
    }

	/* get all files to compile */ 
	auto files = files_to_compile(conf, mfpath);
	files = files.sort;

	/* let's compile them */
	writefln("compiling '%s'", conf.out_name);
	auto filesNb = files.length;
	string[] objs = new string[files.length];
	writefln("compiling %d files...", filesNb);
	foreach (uint i, string file; files) {
		auto obj = file_to_module(file, conf.root);
		obj = ".obj/" ~ obj ~ OBJ_EXT;
		auto state = comp.compile(file, obj, conf.bt, conf.import_dirs);

        if (state != ECompileState.FAIL) {
			objs[i] = obj;
            if (state == ECompileState.COMPILED)
                writefln("--> [%4d%% | %s ] ", cast(int)(((i+1)*100/filesNb)), file);
        }
	}

	debug writefln("-- object files to link: %s", objs);
	/* finally link the program */
	comp.link(objs, output, conf.bt, conf.tt, conf.lib_dirs, conf.libs);
}

version ( none ) {
void build_tests(CConfiguration conf) {
    writefln("building %s%s tests", conf.out_name, conf.out_name[$-1] == 's' ? "'" : "'s");

    foreach (testDir; conf.test_dirs) {
        debug writefln("-- test directory %s", testDir);
        auto tests = dirEntries(testDir, "*.d", SpanMode.depth);
        foreach (test; tests) {
            auto m = file_to_module(test, conf.root);
            build(conf, m, m);
        }
    }
}
}

string scan(CConfiguration conf, string m) {
	writefln("scanning module '%s' for '%s'", m, conf.out_name);
	auto mloader = new CModulesLoader(conf);

	return mloader.scan(m);
}

/* Get the list of the files that are part of the compilation process. */
string[] files_to_compile(CConfiguration conf, string mfpath) {
	writefln("getting files to compile...");

	if (!mfpath.exists) {
		writefln("warning: %s does not exist, aborting...", mfpath);
		throw new CAbortLoading;
	}

	try {
		if (!mfpath.isFile) {
			writefln("warning: %s is not a directory, aborting...", mfpath);
			throw new CAbortLoading;
		}
	} catch (const FileException e) {
		throw e;
	}

	string[] files;
	auto fh = File(mfpath, "r");

	if (!fh.isOpen) {
		writeln("warning: unable to open %s, aborting...", mfpath);
		throw new CAbortLoading;
	}

	foreach (string line; lines(fh)) {
		line = strip(line);
		++files.length;
		files[$-1] = module_to_file(line, conf.root);
		debug writefln("-- added %s to the files to compile", files[$-1]);
	}

	debug writefln("-- files to compile: %s", files);
	return files;
}

void test(CConfiguration conf) {
    writefln("testing '%s'", conf.out_name);

    auto programs = array(dirEntries(".test", SpanMode.depth));
    auto filesNb = programs.length;
    foreach (int i, string t; programs) {
        auto r = system(t);
        writefln("--> [%4d%% | %s ] %s", cast(int)(((i+1)*100/filesNb)), t, (r ? "FAIL" : "OK"));
    }
}

void clean(CConfiguration conf) {
    void remove_dir_(string name) {
        try {
            auto files = array(dirEntries(name, SpanMode.depth));
            foreach (string f; files) {
                remove(f);
				debug writefln("-- removing %s", f);
			}

            rmdir(name);
			debug writefln("-- removing %s", name);
        } catch (FileException e) {
        }
    }

    /* removing the application objects */
    remove_dir_(".obj");
    /* removing the test objects */
    remove_dir_(".objt");
	/* removing the .sdbm modules description files */
	remove_dir_(".sdb_modules"); /* FIXME: fuckit :D */
    /* removing the test programs */
    remove_dir_(".test");

    /* removing the out */
    try {
        remove(conf.out_name);
    } catch (FileException e) {
    }
}
