module pkgconfig

import alexesprit.semver
import os

const (
	default_paths = [
		'/usr/local/lib/pkgconfig/',
		'/usr/lib/pkgconfig/',
	]
	version       = '0.2.0'
)

pub struct Options {
pub:
	path  string
	debug bool
}

pub struct PkgConfig {
pub mut:
	options     Options
	libs        []string
	cflags      []string
	paths       []string // TODO: move to options?
	vars        map[string]string
	requires    []string
	version     string
	description string
	name        string
	modname     string
}

fn (mut pc PkgConfig) filter(s string) string {
	mut r := s.trim_space()
	for r.contains('\${') {
		tok0 := r.index('\${') or {
			break
		}
		tok1 := r.index('}') or {
			break
		}
		v := r[tok0 + 2..tok1]
		r = r.replace('\${$v}', pc.vars[v])
	}
	return r.trim_space()
}

fn (mut pc PkgConfig) setvar(line string) {
	kv := line.trim_space().split('=')
	if kv.len == 2 {
		k := kv[0]
		v := pc.filter(kv[1])
		pc.vars[k] = pc.filter(v)
	}
}

fn (mut pc PkgConfig) parse(file string) bool {
	data := os.read_file(file) or {
		return false
	}
	if pc.options.debug {
		eprintln(data)
	}
	lines := data.split('\n')
	for line in lines {
		if line.starts_with('#') {
			continue
		}
		parse_vars := line.contains('=') && !line.contains(' ')
		if parse_vars {
			pc.setvar(line)
			continue
		}
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
	return true
}

fn (mut pc PkgConfig) resolve(pkgname string) ?string {
	if pc.paths.len == 0 {
		pc.paths << '.'
	}
	for path in pc.paths {
		file := '$path/${pkgname}.pc'
		if os.exists(file) {
			return file
		}
	}
	return error('Cannot find "$pkgname" pkgconfig file')
}

pub fn (mut pc PkgConfig) atleast(v string) bool {
	v0 := semver.from(pc.version) or {
		return false
	}
	v1 := semver.from(v) or {
		return false
	}
	return v0.gt(v1)
}

pub fn (mut pc PkgConfig) extend(pcdep &PkgConfig) ?string {
	for flag in pcdep.cflags {
		if !(flag in pc.cflags) {
			pc.cflags << flag
		}
	}
	for lib in pcdep.libs {
		if !(lib in pc.libs) {
			pc.libs << lib
		}
	}
}

fn (mut pc PkgConfig) load_requires() {
	for dep in pc.requires {
		mut pcdep := PkgConfig{
			paths: pc.paths
		}
		depfile := pcdep.resolve(dep) or {
			break
		}
		pcdep.parse(depfile)
		pcdep.load_requires()
		pc.extend(pcdep)
	}
}

fn (mut pc PkgConfig) add_path(path string) {
	p := if path.ends_with('/') { path[0..path.len - 1] } else { path }
	if pc.paths.index(p) == -1 {
		pc.paths << p
	}
}

fn (mut pc PkgConfig) load_paths() {
	for path in default_paths {
		pc.add_path(path)
	}
	for path in pc.options.path.split(':') {
		pc.add_path(path)
	}
	env_var := os.getenv('PKG_CONFIG_PATH')
	if env_var != '' {
		env_paths := env_var.trim_space().split(':')
		for path in env_paths {
			pc.add_path(path)
		}
	}
}

pub fn load(pkgname string, options Options) ?&PkgConfig {
	mut pc := &PkgConfig{
		modname: pkgname
		options: options
	}
	pc.load_paths()
	file := pc.resolve(pkgname) or {
		return error(err)
	}
	pc.parse(file)
	if pc.name != pc.modname {
		eprintln('Warning: modname and filename differ $pc.name $pc.modname')
	}
	pc.load_requires()
	return pc
}

pub fn list() []string {
	mut pc := &PkgConfig{
		options: Options{}
	}
	pc.load_paths()
	mut modules := []string{}
	for path in pc.paths {
		files := os.ls(path) or {
			continue
		}
		for file in files {
			if file.ends_with('.pc') {
				name := file.replace('.pc', '')
				if modules.index(name) == -1 {
					modules << name
				}
			}
		}
	}
	return modules
}
