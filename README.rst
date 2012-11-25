================
Simple D Builder
================

The `Simple D Builder`, a.k.a `sdb` provides a simple solution to build your D projects. It currently supports compilation and linking. Testing will be supported soon.

I - Getting started
===================

1. Downloading
--------------

You can download `sdb` on github by cloning the official repository:
    ``$ git clone git@github.com:skypers/sdb.git``
You can also use the download section on the `sdb` github home page.
For the arch users, you can just install the `sdb` package I maintain:
    ``# pacman -S sdb``
Or with `yaourt`:
    ``$ yaourt -S sdb``

2. Compiling
------------

Run into the downloaded repo (or extract the archive into a `sdb` directory), then simply compile and link all the .d files with your favourite D compiler. **Note: up to now, only the Digital D Mars compiler (DMD) is supported, the other ones will be supported later**. It is highly recommended to compile `sdb` with the best compilation flags. Here is the DMD case:
    ``$ dmd -release -w -wi -O ...``
It will generate a `sdb` binary file in the same directory.

3. Installing
-------------

There is no support for install steps up to now, so you will have to place `sdb` in the installation directory on your own. On \*nix systems, you can install it into /usr/local/bin, or ~/bin, adjusting your PATH env variable:
    ``$ sudo cp ./sdb /usr/local/bin``

II - Using `sdb`
================

`sdb` has been written in order to make easy the build process of D projects. You just have to learn a few keywords, then you will be able to write your applications like a boss and especially start them very quickly.

1. The configuration file
-------------------------

In order to adapt to your projects, `sdb` uses a configuration file commonly called `.sdb`, but you can change it’s a matter for you.. That file gathers all the project’s main settings. Here is a comprehensive list:

BUILD:
    Build type of the project. It can be **debug** for *debug build* or **release** for *release and optimized build*.
TARGET:
    Target type of the project. It can be **exec** for *executable*, **static** for *static library* or **shared** for *dynamic library*.
IMPORT_DIR:
    List of all directories to look in when resolving imports, separated by blanks.
LIB_DIR:
    List of all directories to look in when resolving libs, separated by blanks. 
LIB:
    List of all libraries to link against.
ROOT:
    Root directory where is located the source modules.
ENTRY_POINT:
    Entry point module of the application.
AUTO_SCAN:
    Auto-scan option used to automatically scan entry points on a build.
TEST_DIR:
    List of all test directories to test, separated by blanks.
OUT_NAME:
    Name of the output of the build.
**Note: the directories' names must not include special characters like ``~`` because such characters are not correctly expanded**.

Each keyword is followed by a blank (or several ones), and by a token or a list of values. Here is a sample:

    ``BUILD debug
    TARGET exec
    ROOT ../src
    ENTRY_POINT main
    OUT_NAME test
    IMPORT_DIR /usr/test
    LIB_DIR ../lib
    LIB DerelictUtil``

The order the keywords appear does not matter, but they have to be upcase.

2. Default configuration
------------------------

Because `sdb` is designed to be simple, it provides a default configuration for each project. Typically, if a particular setting is not set in the configuration file, `sdb` will use its own default. It’s really useful for two reasons: many projects look like each other, so the settings won’t be often changed, and it allows `sdb` to have extra settings — which make it not so simple as it ought to be.

Here’s a comprehensive list of all the current `sdb` defaults:
- `BUILD`: debug
- `TARGET`: exec
- `ROOT`: ../src
- `TEST_DIR`: ../test
- `OUT_NAME`: ./out
- `AUTO_SCAN`: off

As you may have noticed, the default root directory is placed in ../src. That encourages you to do a out-of-src-tree build, in a build-tree. See the samples for projects examples.

3. Module scan and auto scanning entry points 
---------------------------------------------

`sdb` uses two short options to be able to adapt to your project and build it: the root directory and the entry point module. With both those information, it can compile all your files that take part of the final output. But, `sdb` need to scan the entry point module to deduce what other modules it has to build too. That process is called a scan.

A second feature that completes the scan process is the auto scan. When auto scan is on, `sdb` will always scan the entry point on each build order. On big projects where you often compile, it can become a pain. So when the auto scan option is off, `sdb` won’t build anything if you haven’t manually launched a scan. Then a build will be significantly faster.

4. Command Line Interface
-------------------------

`sdb` is a CLI program. Because it aims to be simple, there are a few commands to control the build process:

build:
    Used to build the application.
clean:
    Used to clean the build tree.

You can build your application with the build flag then:

    ``$ sdb build``

There is also a shortcut to the line above:

    ``$ sdb``

III - Support
=============

If you have any problem or find any bug, do not hesitate to contact me at dimitri.sabadie@gmail.com. 
