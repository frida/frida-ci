ARG ARCH=x86_64
FROM quay.io/pypa/manylinux1_$ARCH

LABEL description="A docker image for building portable Linux binaries using modern GCC"
LABEL maintainer="The Frida Project"

ARG ARCH
ARG CORES=8

ARG GCC_VERSION=9.3.0
ARG BINUTILS_VERSION=2.34
ARG XZ_VERSION=5.2.5
ARG TAR_VERSION=1.32
ARG OPENSSH_VERSION=8.2p1
ARG PERL_VERSION=5.30.2

ARG DEVTOOLS_PREFIX=/opt/devtools
ARG DEVTOOLS_CC="$DEVTOOLS_PREFIX/bin/gcc -static-libgcc -fgnu89-inline -fuse-ld=gold"
ARG DEVTOOLS_CXX="$DEVTOOLS_PREFIX/bin/g++ -static-libgcc -static-libstdc++ -fuse-ld=gold"
ARG DEVTOOLS_CFLAGS="-ffunction-sections -fdata-sections"
ARG DEVTOOLS_LDFLAGS="-Wl,--icf=all -Wl,--gc-sections -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now"
ARG RHDEV_PREFIX=/opt/rh/devtoolset-2/root/usr

RUN yum -y update \
    && export FORCE_UNSAFE_CONFIGURE=1
    && yum -y install flex glibc-devel.i386 libgcc.i386 openssl101e-devel texinfo zlib-devel \
    && yum clean all \
    && cd /tmp \
    && curl -L -o gcc.tar.gz "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz" \
    && tar xf gcc.tar.gz \
    && cd gcc-$GCC_VERSION \
    && sed -i 's\ftp://gcc.gnu.org\https://gcc.gnu.org\g' contrib/download_prerequisites \
    && contrib/download_prerequisites \
    && mkdir build \
    && cd build \
    && ../configure \
        --prefix=$DEVTOOLS_PREFIX \
        --enable-checking=release \
        --enable-languages=c,c++ \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && rm -rf gcc.tar.gz gcc-$GCC_VERSION \
    && export \
        PATH="$DEVTOOLS_PREFIX/bin:$PATH" \
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
    && curl -L -o binutils.tar.gz "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz" \
    && tar xf binutils.tar.gz \
    && cd binutils-$BINUTILS_VERSION \
    && ./configure \
        --prefix=$DEVTOOLS_PREFIX \
        --enable-gold \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && rm -rf binutils.tar.gz binutils-$BINUTILS_VERSION \
    && export \
        LD="$DEVTOOLS_PREFIX/bin/ld.gold" \
        AR="$DEVTOOLS_PREFIX/bin/ar" \
        NM="$DEVTOOLS_PREFIX/bin/nm" \
        RANLIB="$DEVTOOLS_PREFIX/bin/ranlib" \
        STRIP="$DEVTOOLS_PREFIX/bin/strip" \
        OBJCOPY="$DEVTOOLS_PREFIX/bin/objcopy" \
        OBJDUMP="$DEVTOOLS_PREFIX/bin/objdump" \
    && curl -L -o xz.tar.gz "https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz" \
    && tar xf xz.tar.gz \
    && cd xz-$XZ_VERSION \
    && ./configure --prefix=$DEVTOOLS_PREFIX \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && rm -rf xz.tar.gz xz-$XZ_VERSION \
    && curl -L -o gnutar.tar.gz "https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.gz" \
    && tar xf gnutar.tar.gz \
    && cd tar-$TAR_VERSION \
    && ./configure --prefix=$DEVTOOLS_PREFIX \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && rm -rf gnutar.tar.gz tar-$TAR_VERSION \
    && curl -L -o openssh.tar.gz "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" \
    && tar xf openssh.tar.gz \
    && cd openssh-$OPENSSH_VERSION \
    && ./configure \
        --prefix=$DEVTOOLS_PREFIX \
        --with-cflags="$(pkg-config --cflags openssl101e)" \
        --with-ldflags="$(pkg-config --libs openssl101e)" \
        --with-libs="/lib64/libcrypt.so.1" \
    && make -j$CORES \
    && make install \
    && strip --strip-all $DEVTOOLS_PREFIX/bin/ssh* \
    && rm -rf $DEVTOOLS_PREFIX/sbin/ $DEVTOOLS_PREFIX/libexec/{sftp,ssh}* \
    && cd /tmp \
    && rm -rf openssh.tar.gz openssh-$OPENSSH_VERSION \
    && curl -L -o perl.tar.gz "https://www.cpan.org/src/5.0/perl-${PERL_VERSION}.tar.gz" \
    && tar xf perl.tar.gz \
    && cd perl-$PERL_VERSION \
    && ./Configure \
        -des \
        -Dprefix=$DEVTOOLS_PREFIX \
        -Dcc=$DEVTOOLS_PREFIX/bin/gcc \
        -Accflags="-fgnu89-inline $DEVTOOLS_CFLAGS" \
        -Aldflags="-static-libgcc -fuse-ld=gold $DEVTOOLS_LDFLAGS" \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && rm -rf perl.tar.gz perl-$PERL_VERSION \
    && rm -rf $DEVTOOLS_PREFIX/share/

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
