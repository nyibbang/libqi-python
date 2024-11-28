#!/bin/sh
set -x -e

PACKAGE=$1

pip install 'conan>=2'

# Perl dependencies required to build OpenSSL.
yum install -y perl-IPC-Cmd perl-Digest-SHA

# Install Conan configuration.
conan profile detect
conan config install "$PACKAGE/ci/conan"

mkdir -p /work

# Clone and export libqi to Conan cache.
git clone \
    --branch master \
    https://github.com/aldebaran/libqi.git \
    /work/libqi
conan export /work/libqi

# Install dependencies of libqi-python from Conan, including libqi.
#
# Build everything from sources, so that we do not reuse precompiled binaries.
# This is because the GLIBC from the manylinux images are often older than the
# ones that were used to build the precompiled binaries, which means the binaries
# cannot by executed.
conan install "$PACKAGE" \
    --build="*" \
    --profile:all default \
    --profile:all cppstd17
    --options cibuildwheel=True
    --output-folder /work/conan
