# Zig Compiler Build Makefile for FreeBSD
# Simplified build process for the cloudbsdorg/zig fork

.PHONY: all clean bootstrap build install test

# Compiler settings
CC ?= cc
CFLAGS ?= -O2
LDFLAGS ?= -Wl,-z,stack-size=0x10000000

# Build directories
BUILD_DIR ?= build
ZIG2_BINARY ?= $(BUILD_DIR)/zig2

# Default target
all: bootstrap build

# Build the bootstrap compiler
bootstrap: bootstrap.c
	@echo "Building bootstrap compiler..."
	$(CC) $(CFLAGS) -o bootstrap bootstrap.c

# Build zig2 from bootstrap
build: bootstrap
	@echo "Building zig2 compiler..."
	./bootstrap build-exe src/main.zig -ofmt=c -lc \
		-OReleaseSmall \
		--name zig2 -femit-bin=$(ZIG2_BINARY) \
		--mod "build_options::config.zig" \
		--mod "aro_options::deps/aro/options.zig" \
		--mod "aro_backend:build_options=aro_options:deps/aro/backend.zig" \
		--mod "aro:Builtins/Builtin.def,Attribute/names.def,Diagnostics/messages.def,build_options=aro_options,backend=aro_backend:deps/aro/aro.zig" \
		--deps build_options,aro \
		-target native
	@echo "Zig2 compiler built successfully: $(ZIG2_BINARY)"

# Build full stage3 compiler (optional, requires zig2)
stage3: build
	@echo "Building stage3 compiler..."
	$(ZIG2_BINARY) build --prefix $(BUILD_DIR)/stage3 \
		-Denable-llvm \
		-Doptimize=ReleaseFast \
		-Dtarget=native

# Install zig2 to system
install: build
	@echo "Installing zig2 to /usr/local/bin..."
	cp $(ZIG2_BINARY) /usr/local/bin/zig
	@echo "Zig compiler installed successfully"

# Run tests
test: build
	@echo "Running Zig tests..."
	$(ZIG2_BINARY) test src/main.zig

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f bootstrap zig2 zig2.c compiler_rt.c
	rm -rf zig-cache zig-out
	@echo "Clean complete"

# Help target
help:
	@echo "Zig Compiler Build Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build bootstrap and zig2 (default)"
	@echo "  bootstrap - Build bootstrap compiler only"
	@echo "  build     - Build zig2 compiler"
	@echo "  stage3    - Build full stage3 compiler (requires LLVM)"
	@echo "  install   - Install zig2 to /usr/local/bin"
	@echo "  test      - Run basic tests"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  CC        - C compiler (default: cc)"
	@echo "  CFLAGS    - C compiler flags (default: -O2)"
	@echo "  BUILD_DIR - Build directory (default: build)"
