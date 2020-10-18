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
* Version comparison logic, maybe having semver
* Strictier pc parsing logic, with better error reporting
