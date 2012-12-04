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

module modules_scanner;

/* This module is used to scan a module to find its dependencies. */

import std.algorithm : countUntil;
import std.array : empty, join;
import std.file;
import std.stdio;
import std.string : strip;
import configuration : CConfiguration;
import common;
import dp_graph;

class CModulesScanner {
    enum MODULES_DIR_SUFFIX = "_modules";
    enum MODULES_FILE_EXT   = ".sdbm";
    
    private {
        const CConfiguration _conf;
    }
    
    this(const CConfiguration conf) {
        _conf = conf;
    }
    
    /* Returns the path of the dir containing the modules caches */
    @property string caches_dir() const {
        return _conf.conf_file_name ~ MODULES_DIR_SUFFIX;
    }
    
    /* Returns the path of the modules cache file for the given entry point */
    string get_cache_path(string path) const {
        return caches_dir ~ dirSeparator ~ path ~ MODULES_FILE_EXT;
    }
    
    /* Launch a modules scan. */
    void scan(string m, CDPGraph graph) {
        debug writefln("-- scanning %s module...", m);
        if (!graph.exists(m))
            graph.add_module(m);
        scan_extract_(m, graph);
        debug writefln("-- scan finished; modules = %s", graph.modules);
    }
    
    /* Scan a module and extract the corresponding modules file. */
    private void scan_extract_(string m, CDPGraph graph) {
        auto path = module_to_file(m, _conf.root);

        if (!is_file(path)) {
            log(ELog.WARNING, "unable to extract modules from '%s'", path);
            return;
        }
        
        string[] toScan;
        { /* File RAII, parallels opened files fix */
            auto fh = File(path, "r");
            if (!fh.isOpen) {
                log(ELog.WARNING, "unable to open %s for scanning", path);
                return;
            }
        
            enum IMPORT_LENGTH = "import ".length;        
            foreach (string line; lines(fh)) {
                line = strip(line);
                if (line.length > IMPORT_LENGTH) {
                    auto importIndex = countUntil(line, "import ");
                    if (importIndex >= 0 && line[$-1] == ';') {
                        line = line[(importIndex + IMPORT_LENGTH) .. countUntil!("a == ';' || a == ':'")(line)];
                        line = strip(line);
                        debug writefln("-- %s imports %s", m, line);
                        //foreach(pre; _conf.import_dirs) {
                            if (module_to_file(line, /*pre*/_conf.root).exists) {
                                /* the module can be accessed from the project root */
                                if (!graph.exists(line)) {
                                    /* the module is not in the graph yet */
                                    graph.add_module(line);
                                    /* modules to scan */
                                    toScan ~= line;
                                    writefln("--> found module '%s'", line);
                                }
                                graph.add_dep(m, line);
                            }
                        //}
                    }
                }
            }
        }

        /* recursively scan the imported modules */
        foreach (_; toScan)
            scan_extract_(_, graph);
    }
    
    void output_scan(string m, CDPGraph graph) {
        auto moddir = _conf.conf_file_name ~ MODULES_DIR_SUFFIX;
        check_modules_dir_(moddir);
        auto path = get_cache_path(m);

        debug writefln("-- outputing the modules in the %s directory", moddir);
        auto fh = File(path, "w");
        
        if (!fh.isOpen) {
            log(ELog.ERROR, "unable to open %s for outputting scan results", path);
            throw new Exception("unable to output scan results");
        }

        foreach (_; graph.modules) {
            auto deps = graph.deps_of(_);
            debug writefln("-- outputing dependencies of %s: %s", _, deps);
            if (deps.empty) { /* no dependency, then just output the module */
                fh.writefln("%s", _);
            } else {
                auto depsStr = join(deps, " ");
                fh.writefln("%s %s", _, depsStr);
            }
        }
        
        debug writefln("-- output finished; modules graph is in %s", moddir);
    }
    
    private void check_modules_dir_(string path) {
        if (!is_dir(path)) {
            debug writefln("-- %s does not exist yet, creating...", path);
            mkdir(path);
        }
    }
}
