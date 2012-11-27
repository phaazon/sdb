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


import std.algorithm : find;

/* This module contains the dependencies graph (modules dependencies). */

final class CDPGraph {
    private {
        string[] _modules; /* all the modules of the project */
        int[] _dep; /* dependencies matrix: (x;y) -> y is a dependency of x */
    }

    this() {
    }

    /* add a module in the graph */
    void add_module(string name) {
        _modules ~= name;
    }

    /* add a new dependency between two modules */
    void add_dep(string x, string y) {
        /* first thing to do: look for both the module to exist */
        auto xf = find(_modules, x); /* x found */
        auto yf = find(_modules, y); /* y found */

        if ( xf.empty || yf.empty ) {
            /* trying to add a dependency between two modules with one of them doesn't exist, abort */
            /* TODO: to rewrite a correct way */
            throw new Exception("(" ~ x ~ ";" ~ y ~ ") is not a valid dependency");
        }

    }
}
