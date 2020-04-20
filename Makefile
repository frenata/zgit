BINARY=zgit

build:
	zig build-exe *.zig

clean:
	rm -f *.o
	rm -f "${BINARY}"
	rm -rf fake/*
