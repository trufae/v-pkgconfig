PREFIX?=/usr/local

all: main

main: main.v pkgconfig/lib.v
	v main.v

test:
	./main --cflags --description r_core

install: main
	cp -f main $(PREFIX)/bin/pkgconfig

uninstall:
	rm -f $(PREFIX)/bin/pkgconfig

clean:
	rm -f main
