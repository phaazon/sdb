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

/* This module is used to retrieve / scan all the modules to be compiled
 * for a givent module. */

import std.algorithm;
import std.file;
import std.stdio;
import std.string : strip;
import configuration : CConfiguration;
import common;

class CModulesLoader {
    enum MODULES_DIR_SUFFIX = "_modules";

    private {
        const CConfiguration _conf;
    }

    this(const CConfiguration conf) {
        _conf = conf;
    }

    /* Launch a modules scan. */
    void scan(string m) {
        string[] modules;

        scan_extract_(m, modules);
    }

    /* Scan a module and extract the corresponding modules file. */
    private void scan_extract_(string m, string[] modules) {
        auto path = module_to_file(m, _conf.root);

        /* TODO: refactor this with the same code as in configuration.d */
        try {
            if (!path.isFile) {
                writefln("warning: %s is not a regular file, aborting...", path);
                throw new CAbortLoading;
            }
        } catch (const FileException e) {
            writefln("warning: %s does not exist, aborting...", path);
            throw new CAbortLoading;
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
                if (line[0 .. IMPORT_LENGTH] == "import " && line[$-1] == ';') {
                    /* valid import */
                    line = line[IMPORT_LENGTH .. countUntil!("a == ';' || a == ':'")(line)-1];
                    strip(line);
                    if (any!(a => a == line)(modules)) {
                        /* the module is not in the build array yet */
                        /* TODO: look if the module is accessible from the root */
                        ++modules.length;
                        modules[$-1] = line;
                        /* modules to scan */
                        ++toScan.length;
                        toScan[$-1] = line;
                        writefln("discovered %s", line);
                    }
                }
            }
        }

        /* recursevily scan the imported modules */
        foreach (_; toScan)
            scan_extract_(_, modules);
    }
}
