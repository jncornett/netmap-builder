Quickstart
==========

In this directory, run

    ./build-netmap.sh --kernel $(uname -r)

This will generate a file, `netmap.ko`, in the current directory

Usage
=====

    Usage: ./build-netmap.sh [--netmap REF] [--output DIR] --kernel VERSION
    Build netmap kernel module for a specific kernel version

    Mandatory arguments:
      --kernel VERSION target kernel version (formatted like `uname -r`)
    Optional arguments:
      --netmap REF github ref OR path to source
               (default: master)
      --output DIR output directory
               (default: $PWD)

Under the hood
==============

> Warning: this part may be outdated. If you really care, read the shell script

1. Build the image
  - `cd ./docker`
  - `docker build -t $IMAGE_NAME .`

2. Fetch netmap
  - `wget -O - https://github.com/$GH_USER/$GH_REPO/archive/$GH_REF.tar.gz | tar xz`
  - `ls ./$GH_REPO-$GH_REF`

3. Build netmap via the docker image
  - `docker run -v $PWD/$GH_REPO-$GH_REF:/src $IMAGE_NAME --kernel $UNAME_R`

4. Copy the build artifact out of the docker image
  - `docker cp $CONTAINER:/out/netmap.ko $PWD`
