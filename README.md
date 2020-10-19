v-pkgconfig
===========

This module implements the `pkg-config` tool as a library in pure V.

Features:

* Simple API, but still not stable, but shouldnt change much
* Commandline tool that aims to be compatible with `pkg-config`
* Resolve full path for `.pc` file given a name
* Recursively parse all the dependencies
* Find and replace all inner variables

Todo/Future/Wish:

* 100% compatibility with `pkg-config` options
* Integration with V, to support pkgconfig with `system()`
* Strictier pc parsing logic, with better error reporting

Example
-------

```
$ ./main -h
pkgconfig 0.2.0
-----------------------------------------------
Usage: pkgconfig [options] [ARGS]

Options:
  -V, --modversion          show version of module
  -d, --description         show pkg module description
  -h, --help                show this help message
  -D, --debug               show debug information
  -l, --list-all            list all pkgmodules
  -e, --exists              return 0 if pkg exists
  -V, --print-variables     display variable names
  -r, --print-requires      display requires of the module
  -a, --atleast-version <string>
                            return 0 if pkg version is at least the given one
  -s, --exact-version <string>
                            return 0 if pkg version is at least the given one
  -v, --version             show version of this tool
  -c, --cflags              output all pre-processor and compiler flags
  -I, --cflags-only-I       show only -I flags from CFLAGS
  - , --cflags-only-other   show cflags without -I
  -l, --libs                output all linker flags
  -   --libs-only-l         show only -l from ldflags
  -L, --libs-only-L         show only -L from ldflags
      --libs-only-other     show flags not containing -l or -L

$
```

