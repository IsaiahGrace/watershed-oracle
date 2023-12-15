#! /bin/zsh

# Let's make sure that we can build locally first
zig build

# Now we'll copy over the source code to the beepy
rsync -avP ~/repos/watershed-oracle beepy:~/repos/ --exclude=zig-cache --exclude=zig-out --exclude=.git

# Next, we'll build the project on the device
echo
echo "Building watershed-oracle on Beepy device"
echo

ssh beepy "cd repos/watershed-oracle; /home/isaiah/zig-linux-armv7a-0.11.0/zig build -Dframebuffer"
