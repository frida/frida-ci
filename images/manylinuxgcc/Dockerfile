ARG ARCH=x86_64
FROM quay.io/pypa/manylinux1_$ARCH

LABEL description="A docker image for building portable Linux binaries using modern GCC"
LABEL maintainer="The Frida Project"

ARG ARCH
ARG CORES=8

ARG GCC_VERSION=9.3.0
ARG BINUTILS_VERSION=2.34

ARG SYSTEM_TRIPLET=$ARCH-redhat-linux
ARG DEVTOOLS_PREFIX=/opt/devtools
ARG DEVTOOLS_CC="$DEVTOOLS_PREFIX/bin/gcc -static-libgcc -fgnu89-inline -fuse-ld=gold"
ARG DEVTOOLS_CXX="$DEVTOOLS_PREFIX/bin/g++ -static-libgcc -static-libstdc++ -fuse-ld=gold"
ARG DEVTOOLS_CFLAGS="-ffunction-sections -fdata-sections"
ARG DEVTOOLS_LDFLAGS="-Wl,--icf=all -Wl,--gc-sections -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now"
ARG RHDEV_PREFIX=/opt/rh/devtoolset-2/root/usr

RUN yum -y update \
    && yum -y install flex texinfo \
    && yum clean all \
    && cd /tmp \
    && curl -L -o gcc.tar.gz "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz" \
    && tar xzf gcc.tar.gz \
    && cd gcc-$GCC_VERSION \
    && sed -i 's\ftp://gcc.gnu.org\https://gcc.gnu.org\g' contrib/download_prerequisites \
    && contrib/download_prerequisites \
    && mkdir build \
    && cd build \
    && ../configure \
        --build=$SYSTEM_TRIPLET \
        --host=$SYSTEM_TRIPLET \
        --target=$SYSTEM_TRIPLET \
        --prefix=$DEVTOOLS_PREFIX \
        --enable-checking=release \
        --enable-languages=c,c++ \
        --disable-multilib \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && curl -L -o binutils.tar.gz "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz" \
    && tar xzf binutils.tar.gz \
    && cd binutils-$BINUTILS_VERSION \
    && mkdir build \
    && cd build \
    && export \
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
    && ../configure \
        --build=$SYSTEM_TRIPLET \
        --host=$SYSTEM_TRIPLET \
        --target=$SYSTEM_TRIPLET \
        --prefix=$DEVTOOLS_PREFIX \
        --enable-gold \
    && make -j$CORES \
    && make install-strip \
    && cd /tmp \
    && rm -rf gcc.tar.gz gcc-$GCC_VERSION binutils.tar.gz binutils-$BINUTILS_VERSION

ENV CPP="$DEVTOOLS_PREFIX/bin/cpp" \
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
