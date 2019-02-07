#!/bin/bash

# Example of using runc as a non-root user with a shared directory
# between the container and the host.
# This will only work as is with kernels that allow overlayfs mounts
# from non-root accounts (such as ubuntu 18.04).

set -e
set -x

mkdir /tmp/runc-shared-dir
cd /tmp/runc-shared-dir/

# pull the busybox docker image and extract it to a directory
mkdir rootfs
docker export $(docker create busybox) | tar -C rootfs -xvf -

mkdir /tmp/shared-dir

# generate a base runc spec file
runc spec --rootless

jq '.mounts += [{ "destination": "/data", "type": "bind", "source": "/tmp/shared-dir", "options": ["rbind","rw"] }]' config.json > config2.json
mv config2.json config.json

# start our rootless container (naming it rootless-example)
runc run shared-dir-example
