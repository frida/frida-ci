ARG ARCH=x86_64
FROM quay.io/pypa/manylinux1_$ARCH

LABEL description="A docker image for building portable Linux binaries using modern GCC"
LABEL maintainer="The Frida Project"

ARG CORES=8

ARG GCC_VERSION=7.5.0
ARG BINUTILS_VERSION=2.34
ARG XZ_VERSION=5.2.5
ARG TAR_VERSION=1.32
ARG OPENSSH_VERSION=8.2p1
ARG PERL_VERSION=5.30.2
ARG NODE_VERSION=13.12.0

ARG DEVTOOLS_PREFIX=/opt/devtools
ARG DEVTOOLS_CC="$DEVTOOLS_PREFIX/bin/gcc -static-libgcc -fgnu89-inline -fuse-ld=gold"
ARG DEVTOOLS_CXX="$DEVTOOLS_PREFIX/bin/g++ -static-libgcc -static-libstdc++ -fuse-ld=gold"
ARG DEVTOOLS_CFLAGS="-ffunction-sections -fdata-sections"
ARG DEVTOOLS_LDFLAGS="-Wl,--icf=all -Wl,--gc-sections -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now"
ARG RHDEV_PREFIX=/opt/rh/devtoolset-2/root/usr

COPY frida-env.rc /tmp/frida-env.rc
COPY patches/node.patch /tmp/node.patch

RUN source /tmp/frida-env.rc \
    && yum -y update \
    && yum -y install flex glibc-devel.i386 libgcc.i386 openssl101e-devel texinfo zlib-devel \
    && yum clean all \
    \
    && export FORCE_UNSAFE_CONFIGURE=1 \
    \
    && frida_enter gcc "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz" \
    && sed -i -e 's\ftp://gcc.gnu.org\https://gcc.gnu.org\g' contrib/download_prerequisites \
    && contrib/download_prerequisites \
    && mkdir build \
    && cd build \
    && ../configure \
        --prefix=$DEVTOOLS_PREFIX \
        --enable-checking=release \
        --enable-languages=c,c++ \
    && make -j$CORES \
    && make install-strip \
    && frida_leave \
    \
    && export \
        PATH="$DEVTOOLS_PREFIX/bin:/opt/python/cp38-cp38/bin:$PATH" \
        CPP="$DEVTOOLS_PREFIX/bin/cpp" \
        CC="$DEVTOOLS_CC" \
        CXX="$DEVTOOLS_CXX" \
        LD="$RHDEV_PREFIX/bin/ld.gold" \
        AR="$DEVTOOLS_PREFIX/bin/gcc-ar" \
        NM="$DEVTOOLS_PREFIX/bin/gcc-nm" \
        RANLIB="$DEVTOOLS_PREFIX/bin/gcc-ranlib" \
        STRIP="$RHDEV_PREFIX/bin/strip" \
        OBJCOPY="$RHDEV_PREFIX/bin/objcopy" \
        OBJDUMP="$RHDEV_PREFIX/bin/objdump" \
        CFLAGS="$DEVTOOLS_CFLAGS" \
        LDFLAGS="$DEVTOOLS_LDFLAGS" \
    \
    && frida_enter binutils "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz" \
    && ./configure \
        --prefix=$DEVTOOLS_PREFIX \
        --enable-gold \
    && make -j$CORES \
    && make install-strip \
    && frida_leave \
    \
    && export \
        LD="$DEVTOOLS_PREFIX/bin/ld.gold" \
        AR="$DEVTOOLS_PREFIX/bin/ar" \
        NM="$DEVTOOLS_PREFIX/bin/nm" \
        RANLIB="$DEVTOOLS_PREFIX/bin/ranlib" \
        STRIP="$DEVTOOLS_PREFIX/bin/strip" \
        OBJCOPY="$DEVTOOLS_PREFIX/bin/objcopy" \
        OBJDUMP="$DEVTOOLS_PREFIX/bin/objdump" \
    \
    && frida_enter xz "https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz" \
    && ./configure --prefix=$DEVTOOLS_PREFIX \
    && make -j$CORES \
    && make install-strip \
    && frida_leave \
    \
    && frida_enter gnutar "https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.gz" \
    && ./configure --prefix=$DEVTOOLS_PREFIX \
    && make -j$CORES \
    && make install-strip \
    && frida_leave \
    \
    && frida_enter openssh "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" \
    && ./configure \
        --prefix=$DEVTOOLS_PREFIX \
        --with-cflags="$(pkg-config --cflags openssl101e)" \
        --with-ldflags="$(pkg-config --libs openssl101e)" \
        --with-libs="/lib64/libcrypt.so.1" \
    && make -j$CORES \
    && make install \
    && strip --strip-all $DEVTOOLS_PREFIX/bin/ssh* \
    && rm -rf $DEVTOOLS_PREFIX/sbin/ $DEVTOOLS_PREFIX/libexec/{sftp,ssh}* \
    && frida_leave \
    \
    && frida_enter perl "https://www.cpan.org/src/5.0/perl-${PERL_VERSION}.tar.gz" \
    && ./Configure \
        -des \
        -Dprefix=$DEVTOOLS_PREFIX \
        -Dcc=$DEVTOOLS_PREFIX/bin/gcc \
        -Accflags="-fgnu89-inline $DEVTOOLS_CFLAGS" \
        -Aldflags="-static-libgcc -fuse-ld=gold $DEVTOOLS_LDFLAGS" \
    && make -j$CORES \
    && make install-strip \
    && frida_leave \
    \
    && frida_enter node "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz" \
    && patch -p1 < /tmp/node.patch \
    && ./configure \
        --prefix=/opt/node \
        --partly-static \
    && make -j$CORES \
    && make install \
    && strip --strip-all /opt/node/bin/node \
    && frida_leave \
    \
    && rm -rf \
        $DEVTOOLS_PREFIX/share/ \
        frida-env.rc

ENV PATH="$DEVTOOLS_PREFIX/bin:$PATH" \
    CPP="$DEVTOOLS_PREFIX/bin/cpp" \
    CC="$DEVTOOLS_CC" \
    CXX="$DEVTOOLS_CXX" \
    LD="$DEVTOOLS_PREFIX/bin/ld.gold" \
    AR="$DEVTOOLS_PREFIX/bin/ar" \
    NM="$DEVTOOLS_PREFIX/bin/nm" \
    RANLIB="$DEVTOOLS_PREFIX/bin/ranlib" \
    STRIP="$DEVTOOLS_PREFIX/bin/strip" \
    OBJCOPY="$DEVTOOLS_PREFIX/bin/objcopy" \
    OBJDUMP="$DEVTOOLS_PREFIX/bin/objdump" \
    CFLAGS="$DEVTOOLS_CFLAGS" \
    LDFLAGS="$DEVTOOLS_LDFLAGS"

ENTRYPOINT ["/bin/bash"]
