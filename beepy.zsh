#! /bin/zsh

set -e

# Build locally, which will build both native and ARM versions of the code
# Also, forward args from this script to zig, so we can do things like `./beepy.zsh -Doptimize=ReleaseSafe`
zig build $@

# Copy the binaries over to the Beepy, changing the binary names
rsync -avP zig-out/bin/arm-* beepy:~/
