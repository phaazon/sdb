================
Simple D Builder
================
The `Simple D Builder`, a.k.a `sdb` provides a simple solution to build your D projects.
It currently supports compilation and linking. Testing will be supported soon.

I - Getting started
===================
1. Downloading
--------------
You can download `sdb` on github by cloning the official repository:

``$ git clone git@github.com:skypers/sdb.git``

You can also use the download section on the `sdb` github home page.
For the arch users, you can just install the `sdb` package I maintain in the AUR:

``$ yaourt -S sdb``

2. Compiling
------------
Run into the downloaded repo (or extract the archive into a `sdb` directory), then simply
compile and link all the .d files with your favourite D compiler. It is highly recommended
to compile `sdb` with the best compilation flags.

Another important point: `sdb` lets you place its configuration where you want on your disk.
You just have to put the full path of the directory where you want `sdb` to look for its
configuration in the ``conf_dir.dcfg`` file. Depending on your operating system, that file is
located in a different directory in the ``conf/`` directory. For instance, on Windows, the file
is ``conf/windows/conf_dir.dcfg``. On linux, it’s recommended not to change the default,
``conf/linux/conf_dir.dcfg``, which is ``/etc/sdb/``. On Windows, you **have** to specify the
folder, for instance:

``C:\Users\your_nick\Documents\sdb``

The name of the directory configuration doesn’t matter because `sdb` will know it once it’s been
compiled.

You have to pass the path of the directory where your compiler will search the ``conf_dir.dcfg``
file. For instance, with dmd, the path can be pass using the ``-Jpath`` flag.

Here’s the complete set of commands to build `sdb` for a linux machine with a custom
configuration directory (``~/.sdb.d``) using rdmd:

::

    $ cd sdb
    $ mkdir ~/.sdb.d
    $ echo "~/.sdb.d" > conf/linux/conf_dir.dcfg
    $ cd src
    $ rdmd --build-only -release -w -wi -O -J../conf/linux sdb

It will generate a `sdb` binary file in ``src/``.

3. Installing
-------------
There is no support for install steps up to now, so you will have to place `sdb` in the
installation directory on your own. On \*nix systems, you can install it into ``/usr/local/bin/``
or ``~/bin/`` for instance, adjusting your ``PATH`` environment variable:

::

    $ cd sdb/src
    $ cp ./sdb ~/bin

For now, you can’t build anything because you don’t have any configured compilers for `sdb`. In the
``conf/compilers/`` directory, you’ll find a lot of ``.conf`` configuration files, for instance
``dmd.conf``. Each of those files represents the set of parameters `sdb` needs to use the given
compiler. Then, the ``dmd.conf`` file gathers all information `sdb` needs in order to allow you to use dmd
within `sdb`.

You can just copy those files in the `sdb` configuration file you set before. Example:

::

    $ cd sdb/conf/compilers
    $ cp *.conf ~/.sdb.d

That’s all!

II - Using `sdb`
================
`sdb` has been written in order to make easy the build process of D projects. You just have to
learn a few keywords, then you will be able to write your applications like a boss and especially
start them very quickly.

1. The configuration file
-------------------------
In order to adapt to your projects, `sdb` uses a configuration file commonly called ``.sdb``, but you
can do what you want if it’s a matter for you.. That file gathers all the project’s main settings. Here is a
comprehensive list:

TARGET:
    Target type of the project. It can be **exec** for *executable*, **static** for *static library*
    or **shared** for *dynamic library*.
IMPORT_DIR:
    List of all directories to look in when resolving imports, separated by blanks.
LIB_DIR:
    List of all directories to look in when resolving libs, separated by blanks. 
LIB:
    List of all libraries to link against.
ROOT:
    Root directory in which are located the source modules.
ENTRY_POINT:
    Entry point module of the application.
OUT_NAME:
    Name of the output of the build.
**Note: the directories' names must not include special characters like ``~`` because such
characters are not correctly expanded**.

Each keyword is followed by a space (or several ones), and by a value or a list of ones.
Here is a sample:

::

    TARGET exec
    ROOT ../src
    ENTRY_POINT main
    OUT_NAME test
    IMPORT_DIR /usr/test
    LIB_DIR ../lib
    LIB DerelictUtil

The order the keywords appear does not matter, but they have to be upcase. Also, the directory
separator doesn’t matter, `sdb` will know what you meant when running on a specifc operating
system, so choose you favourite one :).

2. Default configuration
------------------------
Because `sdb` is designed to be simple, it provides a default configuration for each project.
Typically, if a particular setting isn’t set in the configuration file, `sdb` will use its
own default. It’s really useful and powerful for two reasons: many projects look like each other,
so the settings won’t be often changed, and it allows `sdb` to have extra settings — which make
it not so simple as it ought to be.

Here’s a comprehensive list of all current `sdb` defaults:

- ``debug``
- **TARGET**: ``exec``
- **ROOT**: ``../src``
- **TEST_DIR**: ``../test``
- **OUT_NAME**: ``./out``
- **AUTO_SCAN**: ``off``

As you may have noticed, the default root directory is placed in ``../src``. That encourages
you to do a *out-of-src-tree* build, in a *build-tree*. See the samples for projects examples.

3. Module scan
--------------
`sdb` uses two short options to be able to adapt to your project and build it: the root directory
and the entry point module. With both those information, it can compile all your files that take
part of the final output. However, `sdb` needs to scan the entry point module to deduce what other
modules it has to build too. That process is called a *scan*, or *caching modules*. Moreover, `sdb`
tracks dependencies between modules in order to update modules that ought to be.


4. Command Line Interface
-------------------------
`sdb` is a CLI program. Because it aims to be simple, there are a few commands to control the build
process:

build:
    Used to build the application.
with:
    Prefix of the compiler to use, which has to follow on the command line.
as:
    Prefix of the build type to use, wich has to follow on the command line (``debug`` or ``release``).
scan:
    Used to launch a scan on the entry point.
clean:
    Used to clean the build tree.

To build your project, you have to:

1. if you haven’t scanned it yet, scan it;
2. once it’s scanned, build it with the compiler of your choice.

5. Examples
-----------

Here are some examples with dmd:

::

    $ sdb scan
    $ sdb build with dmd
    $ sdb with dmd build # same as the line above
    $ sdb with dmd # ditto
    $ vim ../src/foo/bar/zoo.d # assume we edit that file
    $ sdb with dmd # ok since ../src/foo/bar/zoo was scanned too
    $ touch ../src/fail.d
    $ sdb with dmd # ../src/fail.d is not compiled
    $ sdb scan build with dmd # launch a brand new scan, then ../src/fail.d is found
    $ ./app.bin # launch your app (debug)
    $ sdb clean
    $ sdb scan
    $ sdb with gdc as release # compile the application for release

III - Support
=============
If you have any problem or find any bug, do not hesitate to contact me at dimitri.sabadie@gmail.com. 
