PREFIX?=/usr/local

all: bin/pkgconfig

bin/pkgconfig: bin/pkgconfig.v lib.v
	v bin/pkgconfig.v

prod: bin/pkgconfig.v lib.v
	v -prod bin/pkgconfig.v

test:
	./bin/pkgconfig --cflags --description r_core

install: bin/pkgconfig
	cp -f bin/pkgconfig $(PREFIX)/bin/pkgconfig

pinstall: prod
	$(MAKE) install

uninstall:
	rm -f $(PREFIX)/bin/pkgconfig

clean:
	rm -f bin/pkgconfig

fmt:
	v fmt -w lib.v bin/pkgconfig.v
