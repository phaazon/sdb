================
Simple D Builder
================

The `Simple D Builder`, a.k.a `sdb` provides a simple solution to build your D projects. It currently supports compilation and linking. Testing will be soon supported.

I - Getting started
===================

1. Downloading
--------------

You can download `sdb` on github by cloning the official repository:
    ``$ git clone git@github.com:skypers/sdb.git``
You can also use the download section on the `sdb` github home page.

2. Compiling
------------

Run into the downloaded repo (or extract the archive into a sdb directory), then simply compile and link the sdb.d file with your favourite D compiler. **Note: up to now, only the Digital D Mars compiler (DMD) is supported, the other ones will be supported later**. It is highly recommended to compile `sdb` with the best compilation flags. Here is the DMD example:

    ``$ dmd -release -w -wi -O sdb.d``

It will generate a `sdb` binary file in the same directory.

3. Installing
-------------

There is no support for installation steps up to now, so you will have to place `sdb` in the installation directory on your own. On \*nix systems, you can install it into /usr/local/bin:

    ``$ sudo cp ./sdb /usr/local/bin``

II - Using `sdb`
================

`sdb` has been written in order to make easy the build process of D projects. You just have to learn a few keywords, then you will be able to write your applications like a boss and especially start them very quickly.

1. The configuration file
-------------------------

In order to adapt to your projects, `sdb` uses a configuration file commonly called `.sdb`. This file gathers all the project’s main settings. Here is a comprehensive list:

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
SRC_DIR:
    List of all src directories to compile, separated by blanks.
TEST_DIR:
    List of all test directories to test, separated by blanks.
OUT_NAME:
    Name of the output of the build.
**Note: the directories' names must not include special characters like ``~`` because such characters are not correctly expanded**.

Each keyword is followed by a blank (or several ones), and by a token or a list of values. Here is a sample:

    ``BUILD debug``
    ``TARGET exec``
    ``SRC_DIR ../src``
    ``OUT_NAME test``
    ``IMPORT_DIR /usr/test``
    ``LIB_DIR ../lib``
    ``LIB DerelictUtil``

The order the keywords appear does not matter, but they have to be upcase.

2. Command Line Interface
-------------------------

`sdb` is a CLI program. Because it aims to be simple, there are a few commands to control the build process:

build:
    Used to build the application.
btest:
    Used to build the tests of the application.
test:
    Used to run all the tests of the application.
clean:
    Used to clean the build tree.
install:
    Used to install the application.
uninstall:
    Used to uninstall the application.
**Note: up to now, only the build flags `build`, `btest` and `clean` are supported**. 

You can build your application with the build flag then:

    ``$ sdb build``

There is also a shortcut to the line above:

    ``$ sdb``

III - Support
=============

If you have any problem or find any bug, do not hesitate to contact me at sabadie.dimitri@gmail.com. 
