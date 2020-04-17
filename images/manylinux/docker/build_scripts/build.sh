#!/bin/bash

set -ex

MY_DIR=$(dirname "${BASH_SOURCE[0]}")
. $MY_DIR/build_env.sh

COMPILE_DEPS="\
    bzip2-devel \
    bzip2-devel.i386 \
    db4-devel \
    db4-devel.i386 \
    expat-devel \
    expat-devel.i386 \
    gdbm-devel \
    gdbm-devel.i386 \
    gpg \
    libpcap-devel \
    libpcap-devel.i386 \
    libX11-devel \
    libX11-devel.i386
    ncurses-devel \
    ncurses-devel.i386 \
    pkgconfig \
    readline-devel \
    readline-devel.i386 \
    tk-devel \
    tk-devel.i386 \
    zlib-devel \
    zlib-devel.i386 \
    "

source $MY_DIR/build_helpers.sh

yum -y erase wget
yum -y install ${COMPILE_DEPS}

build_perl

build_openssl

build_curl
hash -r
curl --version
curl-config --features

build_m4
m4 --version
build_autoconf
autoconf --version
build_automake
automake --version
build_libtool
libtool --version

build_xz

build_tar

build_patchelf

build_sqlite

build_libffi

build_libxcrypt

build_openssh

build_git
git version

mkdir -p /opt/python-{32,64}
build_cpythons $CPYTHON_VERSIONS

build_nodes

PY38_BIN=/opt/python-64/cp38-cp38/bin
$PY38_BIN/pip install --require-hashes -r $MY_DIR/py38-requirements.txt
ln -s $($PY38_BIN/python -c 'import certifi; print(certifi.where())') \
      /opt/_internal/certs.pem
# If you modify this line you also have to modify the versions in the
# Dockerfiles:
export SSL_CERT_FILE=/opt/_internal/certs.pem

yum -y erase \
    avahi \
    bitstream-vera-fonts \
    freetype \
    gtk2 \
    hicolor-icon-theme \
    libX11 \
    wireless-tools \
    ${COMPILE_DEPS} \
    > /dev/null 2>&1
yum -y clean all > /dev/null 2>&1
yum list installed

find /opt/_internal -name '*.a' -print0 | xargs -0 rm -f

find /opt/_internal -type f -print0 \
    | xargs -0 -n1 strip --strip-unneeded 2>/dev/null || true

find /opt/_internal -depth \
     \( -type d -a -name test -o -name tests \) \
  -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) | xargs rm -rf

rm -rf \
    $DEVTOOLS_PREFIX/bin/{c_rehash,curl-config,openssl} \
    $DEVTOOLS_PREFIX/include/{curl,libffi*,lzma*,openssl*,sqlite*} \
    $DEVTOOLS_PREFIX/lib{,64}/lib{crypto*,ffi*,lzma*,sqlite*,ssl*} \
    $DEVTOOLS_PREFIX/lib{,64}/{engines*,pkgconfig}/ \
    $DEVTOOLS_PREFIX/share/{doc,info,locale,man}

for PYTHON in /opt/python-*/*/bin/python; do
  $PYTHON $MY_DIR/manylinux1-check.py
  $PYTHON $MY_DIR/ssl-check.py
done
