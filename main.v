module main

import os
import flag
import pkgconfig

fn main() {
	mut fp := flag.new_flag_parser(os.args[1..])
	fp.application('pkgconfig')
	fp.version(pkgconfig.version)
	show_modversion := fp.bool('modversion', `V`, false, 'show version of module')
	show_version := fp.bool('version', `v`, false, 'show version of this tool')
	show_cflags := fp.bool('cflags', `c`, false, 'output all pre-processor and compiler flags')
	show_libs := fp.bool('libs', `l`, false, 'output all linker flags')
	// pkgconfig_path := '/usr/local/lib/pkgconfig'
	options := pkgconfig.PkgConfigOptions {
	}
	pc := pkgconfig.load('r_core', options) or {
		eprintln(err)
		exit(1)
	}
	mut res := ''
	if show_cflags {
		res += pc.cflags.join(' ')
	}
	if show_libs {
		res += pc.libs.join(' ')
	}
	if show_version {
		res = pkgconfig.version
	}
	if show_modversion {
		res = pc.version
	}
	if res != '' {
		println(res)
		exit(0)
	}
	// println(r2.description)
}
