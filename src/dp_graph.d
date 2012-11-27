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

module dp_graph;

import std.algorithm : countUntil, find;
import std.array : empty;

/* This module contains the dependencies graph (modules dependencies). */

final class CDPGraph {
    private {
        string[] _modules; /* all the modules of the project */
        int[] _dep; /* dependencies matrix: (x;y) -> x depends on y */
    }

    this() {
    }

    /* add a module in the graph */
    void add_module(string name) {
        auto l = _modules.length;

        /* add the module to the graph */
        _modules ~= name;
        /* expand the adjacency matrix */
        auto last = _dep;
        _dep = new int[]((l + 1) * (l + 1));
        uint i;
        foreach (x; 0 .. l) { /* for each line */
            foreach (y; 0 .. l) { /* for each column */
                i = x*l + y;
                _dep[i] = last[i];
            }
        }
    }

    /* add a new dependency between two modules */
    void add_dep(string x, string y) {
        /* first thing to do: look for both the modules to exist */
        auto xf = countUntil(_modules, x); /* x found */
        auto yf = countUntil(_modules, y); /* y found */

        if (xf < 0) {
            throw new Exception("'" ~ x ~ "' is an unkown module");
        } else if (yf < 0) {
            throw new Exception("'" ~ y ~ "' is an unkown module");
        }
        
        /* create the arc */
        _dep[xf*_modules.length + yf] = true;
    }
    
    /* returns true if the module is in the graph, false otherwise */
    bool exists(string m) const {
        return !find(_modules, m).empty;
    }
    
    /* returns all the dependencies of a module */
    /* TODO */
    string[] dependencies_of(string m) const {
        string[] deps;
        auto l = _modules.length
        
        foreach (y; 0 .. l) {
        }
    }
}
