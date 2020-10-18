module pkgconfig

import os

const (
	default_paths = [
		'/usr/local/lib/pkgconfig/'
		'/usr/lib/pkgconfig/'
	]
	version = '0.1.0'
)

pub struct PkgConfigOptions {
pub mut:
	path string
}

pub struct PkgConfig {
pub mut:
	options PkgConfigOptions
	libs []string
	cflags []string
	paths []string // TODO: move to options?
	vars map[string]string
	requires []string
	version string
	description string
	name string
}

fn (mut pc PkgConfig)filter(s string) string {
	mut r := s.trim_space()
	// TODO: just take anything between ${}
	for r.contains('\${') {
		tok0 := r.index('\${') or { break }
		tok1 := r.index('}') or { break }
		v := r[tok0+2..tok1]
		r = r.replace('\${$v}', pc.vars[v])
	}
	return r.trim_space()
}

fn (mut pc PkgConfig)setvar(line string) {
	kv := line.trim_space().split('=')
	if kv.len == 2 {
		k := kv[0]
		v := pc.filter(kv[1])
		pc.vars[k] = pc.filter(v)
	}
}

fn (mut pc PkgConfig)parse(file string) bool {
	data := os.read_file(file) or {
		return false
	}
	mut parse_vars := true
	lines := data.split('\n')
	for line in lines {
		if line == '' {
			parse_vars = false
		} else {
			if parse_vars {
				pc.setvar(line)
			} else {
				if line.starts_with('Description: ') {
					pc.description = pc.filter(line[13..])
				} else if line.starts_with('Cflags: ') {
					pc.cflags = pc.filter(line[8..]).split(' ')
				} else if line.starts_with('Libs: ') {
					pc.libs = pc.filter(line[6..]).split(' ')
				} else if line.starts_with('Name: ') {
					pc.name = pc.filter(line[6..])
				} else if line.starts_with('Version: ') {
					pc.version = pc.filter(line[9..])
				} else if line.starts_with('Requires: ') {
					pc.requires = pc.filter(line[10..]).split(' ')
				}
			}
		}
	}
	return true
}

fn (mut pc PkgConfig)resolve(pkgname string) ?string {
	if pc.paths.len == 0 {
		pc.paths << '.'
	}
	for path in pc.paths {
		file := '${path}/${pkgname}.pc'
		if os.exists(file) {
			return file
		}
	}
	return error('Cannot find "${pkgname}" pkgconfig file')
}

fn (mut pc PkgConfig)extend(pcdep &PkgConfig) ?string {
	for flag in pcdep.cflags {
		if !(flag in pc.cflags) {
			pc.cflags << flag
		}
	}
	for lib in pcdep.libs {
		if !(lib in pc.libs ) {
			pc.libs << lib
		}
	}
}

pub fn load(pkgname string, options PkgConfigOptions) ?&PkgConfig {
	mut pc := &PkgConfig {
		options: options
	}
	pc.paths = options.path.split(':')
	for path in default_paths {
		pc.paths << path
	}
	env_var := os.getenv('PKG_CONFIG_PATH')
	if env_var != '' {
		env_paths := env_var.trim_space().split(':')
		for path in env_paths {
			pc.paths << path
		}
	}
	file := pc.resolve(pkgname) or {
		return error(err)
	}
	pc.parse(file)
	for dep in pc.requires {
		mut pcdep := PkgConfig {
			paths: pc.paths
		}
		depfile := pcdep.resolve(dep) or {
			return error(err)
		}
		pcdep.parse(depfile)
		pc.extend(pcdep)
	}
	return pc
}
