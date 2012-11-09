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

module modules_loader;

import std.algorithm : countUntil;
import std.array : empty;
import std.file;
import std.stdio;
import std.string : strip;
import configuration : CConfiguration;
import common;

/* This module is used to retrieve / scan all the modules to be compiled
for a given module. */

class CModulesLoader {
    enum MODULES_DIR_SUFFIX = "_modules";
    enum MODULES_FILE_EXT   = ".sdbm";
    
    private {
        const CConfiguration _conf;
    }
    
    this(const CConfiguration conf) {
        _conf = conf;
    }
    
    /* Launch a modules scan and output the result in the corresponding file. */
    string scan(string m) {
        string[] modules;
        string moddir = _conf.conf_file_name ~ MODULES_DIR_SUFFIX;
		
        debug writefln("-- scanning %s module...", m);
        scan_extract_(m, modules);
        debug writefln("-- scan finished; modules = %s", modules);
        
        debug writefln("-- outputing the modules in %s", moddir);
        check_modules_dir_(moddir);
        
		moddir = moddir ~ '/' ~ m ~ MODULES_FILE_EXT;
        auto fh = File(moddir, "w");
        /* TODO: treat the case when it's not open. */
        if (fh.isOpen) {
			fh.writeln(m);
            foreach (_; modules)
                fh.writeln(_);
        } else {
            debug writefln("-- unable to write %s modules file", moddir);
        }

		return moddir;
    }
    
    /* Scan a module and extract the corresponding modules file. */
    private void scan_extract_(string m, ref string[] modules) {
        auto path = module_to_file(m, _conf.root);

        try {
            if (!path.isFile)
                return;
        } catch (const FileException e) {
            return;
        }
        
        auto fh = File(path, "r");
        if (!fh.isOpen) {
            writefln("warning: unable to open %s", path);
            throw new CAbortLoading;
        }
        
        string[] toScan;
        enum IMPORT_LENGTH = "import ".length;        
        foreach (string line; lines(fh)) {
            line = strip(line);
            if (line.length > IMPORT_LENGTH) {
				auto importIndex = countUntil(line, "import ");
                if (importIndex >= 0 && line[$-1] == ';') {
                    line = line[(importIndex + IMPORT_LENGTH) .. countUntil!("a == ';' || a == ':'")(line)];
                    strip(line);
                    debug writefln("-- %s imports %s", path, line);
                    if (!any!((string a) => a == line)(modules)) {
                        /* the module is not in the build array yet */
                        if (module_to_file(line, _conf.root).exists) {
                            /* the module can be accessed from the project root */
                            ++modules.length;
                            modules[$-1] = line;
                            /* modules to scan */
                            ++toScan.length;
                            toScan[$-1] = line;
                            writefln("--> found module '%s'", line);
                        }
                    }
                }
            }
        }

        /* recursively scan the imported modules */
        foreach (_; toScan)
            scan_extract_(_, modules);
    }
    
    private void check_modules_dir_(string path) {
        try {
            if (!path.isDir) {
                writefln("%s is not a directory but it ought to be, aborting...");
                throw new CAbortLoading;
            }
        } catch (const FileException e) {
            /* create the dir */
            debug writefln("-- %s does not exist yet, creating...", path);
            mkdir(path);
        }
    }
}
