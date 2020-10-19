module main

import os
import flag
import pkgconfig

struct Main {
mut:
	opt &Options
	res string
	has_actions bool
}

struct Options {
	modversion bool
	description bool
	help       bool
	debug      bool
	listall    bool
	exists     bool
	variables  bool
	requires   bool
	atleast    string
	exactversion string
	version    bool
	cflags     bool
	cflags_only_path     bool
	cflags_only_other bool
	libs       bool
	libs_only_link  bool
	libs_only_path  bool
	libs_only_other bool
	args       []string
}


// UU main UU
fn main() {
	mut main := pkgconfig_main(os.args[1..]) or {
		eprintln(err)
		exit(1)
	}
	main.res = main.run() or {
		eprintln(err)
		exit(1)
	}
	if main.res != '' {
		println(main.res)
	}
}
// OO main OO

fn pkgconfig_main(args []string) ?&Main {
	mut m := &Main{}
	mut fp := flag.new_flag_parser(os.args[1..])
	fp.application('pkgconfig')
	fp.version(pkgconfig.version)
	opt := parse_options(mut fp)
	m.opt = opt

	if opt.help {
		m.res = fp.usage().replace('- ,', '   ')
	} else if opt.version {
		m.res = pkgconfig.version
	} else if opt.listall {
		m.res = pkgconfig.list().join('\n')
	} else if opt.args.len == 0 {
		return error('No packages given')
	}
	return m
}

fn (mut m Main)run() ?string {
	opt := m.opt
	options := pkgconfig.Options {
		// path := '/usr/local/lib/pkgconfig'
		debug: opt.debug
	}
	mut pc := &pkgconfig.PkgConfig(0)
	mut res := m.res
	for arg in opt.args {
		mut pcdep := pkgconfig.load(arg, options) or {
			if !opt.exists {
				return error(err)
			}
			continue
		}
		if opt.description {
			if res != '' {
				res += '\n'
			}
			res += pcdep.description
		}
		if pc != 0 {
			pc.extend(pcdep)
		} else {
			pc = pcdep
		}
	}
	if opt.exists {
		return res
	}
	if opt.exactversion != '' {
		if pc.version != opt.exactversion {
			return error('version mismatch')
		}
		return res
	}
	if opt.atleast != '' {
		if pc.atleast(opt.atleast) {
			return error('version mismatch')
		}
		return res
	}
	if opt.variables {
		for k, _ in pc.vars {
			res += '$k\n'
		}
	}
	if opt.requires {
		res += pc.requires.join('\n')
	}
	if opt.cflags_only_path {
		res += filter(pc.cflags, '-I', '')
	}
	if opt.cflags_only_other {
		res += filter(pc.cflags, '-I', '-I')
	}
	if opt.cflags {
		res += pc.cflags.join(' ')
	}
	if opt.libs_only_link {
		res += filter(pc.libs, '-l', '')
	}
	if opt.libs_only_path {
		res += filter(pc.libs, '-L', '')
	}
	if opt.libs_only_other {
		res += filter(pc.libs, '-l', '-L')
	}
	if opt.libs {
		res += pc.libs.join(' ')
	}
	if opt.modversion {
		res = pc.version
	}
	return res
}

fn filter(libs []string, prefix string, prefix2 string) string {
	mut res := ''
	if prefix2 != '' {
		for lib in libs {
			if !lib.starts_with(prefix) && !lib.starts_with(prefix2) {
				res += ' $lib'
			}
		}
	} else {
		for lib in libs {
			if lib.starts_with(prefix) {
				res += ' $lib'
			}
		}
	}
	return res
}

fn parse_options(mut fp flag.FlagParser) &Options {
	return &Options {
		description: fp.bool('description', `d`, false, 'show pkg module description')
		modversion:  fp.bool('modversion', `V`, false, 'show version of module')
		help:        fp.bool('help', `h`, false, 'show this help message')
		debug:       fp.bool('debug', `D`, false, 'show debug information')
		listall:     fp.bool('list-all', `l`, false, 'list all pkgmodules')
		exists:      fp.bool('exists', `e`, false, 'return 0 if pkg exists')
		variables:   fp.bool('print-variables', `V`, false, 'display variable names')
		requires:    fp.bool('print-requires', `r`, false, 'display requires of the module')
		atleast:     fp.string('atleast-version', `a`, '', 'return 0 if pkg version is at least the given one')
		exactversion:fp.string('exact-version', `s`, '', 'return 0 if pkg version is at least the given one')
		version:     fp.bool('version', `v`, false, 'show version of this tool')
		cflags:      fp.bool('cflags', `c`, false, 'output all pre-processor and compiler flags')
		cflags_only_path: fp.bool('cflags-only-I', `I`, false, 'show only -I flags from CFLAGS')
		cflags_only_other: fp.bool('cflags-only-other', ` `, false, 'show cflags without -I')
		libs:        fp.bool('libs', `l`, false, 'output all linker flags')
		libs_only_link: fp.bool('libs-only-l', ` `, false, 'show only -l from ldflags')
		libs_only_path: fp.bool('libs-only-L', `L`, false, 'show only -L from ldflags')
		libs_only_other: fp.bool('libs-only-other', ` `, false, 'show flags not containing -l or -L')
		args:        fp.args
	}
}
