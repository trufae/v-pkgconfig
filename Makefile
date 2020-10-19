PREFIX?=/usr/local

all: main

main: main.v pkgconfig/lib.v
	v main.v

prod:
	v -prod main.v

test:
	./main --cflags --description r_core

install: main
	cp -f main $(PREFIX)/bin/pkgconfig

pinstall: prod
	$(MAKE) install

uninstall:
	rm -f $(PREFIX)/bin/pkgconfig

clean:
	rm -f main

fmt:
	v fmt -w main.v pkgconfig/lib.v
