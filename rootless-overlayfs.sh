#!/bin/bash

# Example of using runc as a non-root user with an overlayfs
# root file system.
# This will only work as is with kernels that allow overlayfs mounts
# from non-root accounts (such as ubuntu 18.04).

set -e
set -x

mkdir /tmp/runc-rootless
cd /tmp/runc-rootless/

# pull the busybox docker image and extract it to a directory
mkdir ro-rootfs
docker export $(docker create busybox) | tar -C ro-rootfs -xvf -

# setup diretories for overlayfs
mkdir upper
mkdir work
mkdir dummy

# generate a base runc spec file
runc spec --rootless

# update the "root" config to the following
# "root": {
#   "path: "dummy"
#   "readonly": false
# }
jq '.root.path = "dummy"' config.json > config2.json
mv config2.json config.json
jq '.root.readonly = false' config.json > config2.json
mv config2.json config.json

# Add a new entry in the "mounts" array for our real root filesystem
# using overlayfs:
# {
#   "destination": "/",
#   "type": "overlay",
#   "source": "overlay",
#   "options": [
#     "rw",
#     "upperdir=/tmp/runc-rootless/upper",
#     "lowerdir=/tmp/runc-rootless/ro-rootfs",
#     "workdir=/tmp/runc-rootless/work"
#   ]
# },
jq '.mounts = [{ "destination" : "/", "type" : "overlay", "source" : "overlay", "options" : [ "rw", "upperdir=/tmp/runc-rootless/upper", "lowerdir=/tmp/runc-rootless/ro-rootfs", "workdir=/tmp/runc-rootless/work"] }] + .mounts' config.json > config2.json
mv config2.json config.json

# start our rootless container (naming it rootless-example)
runc run rootless-example
