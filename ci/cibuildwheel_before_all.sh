#!/bin/sh
set -x -e

PACKAGE_DIR=$1
DEPS_DIR="$PACKAGE_DIR/build/deps"
mkdir -p "$DEPS_DIR"

pip install 'conan>=2'

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Perl dependencies required to build OpenSSL.
    yum install -y perl-IPC-Cmd perl-Digest-SHA
fi

# Install Conan configuration.
conan profile detect
conan config install "$PACKAGE_DIR/ci/conan"

# Clone and export libqi to Conan cache.
git clone \
    --branch master \
    https://github.com/aldebaran/libqi.git \
    "$DEPS_DIR/libqi-git"
conan export "$DEPS_DIR/libqi-git"

# Install dependencies of libqi-python from Conan, including libqi.
#
# Build everything from sources, so that we do not reuse precompiled binaries.
# This is because the GLIBC from the manylinux images are often older than the
# ones that were used to build the precompiled binaries, which means the binaries
# cannot by executed.
conan install "$PACKAGE_DIR" \
    --build="*" \
    --profile:all default \
    --profile:all cppstd17
    --options cibuildwheel=True
    --output-folder "$DEPS_DIR"
