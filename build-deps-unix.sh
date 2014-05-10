#!/bin/bash

if [ -z "$FRIDA_ROOT" ] ; then
  echo "Must set FRIDA_ROOT env var first"
  exit 1
fi

if [ -z "$CONFIG_SITE" ]; then
  echo "This script must be run from within a Frida build environment." > /dev/stderr
  echo "Run setup-env.sh to create one." > /dev/stderr
  exit 1
fi

build_platform=$(uname -s | tr '[A-Z]' '[a-z]' | sed 's,^darwin$$,mac,')

case $build_platform in
  linux)
    download_command="wget -O - -q"
    tar_stdin=""
    ;;
  mac)
    download_command="curl -sS"
    tar_stdin="-"
    ;;
  *)
    echo "Could not determine build platform" > /dev/stderr
    exit 1
esac

if [ -n $FRIDA_HOST ]; then
  host_platform=$(echo -n $FRIDA_HOST | sed 's,\([a-z]\+\)-\(.\+\),\1,g')
else
  host_platform=$build_platform
fi
if [ $host_platform = 'linux' ]; then
  host_distro=$(lsb_release -is | tr '[A-Z]' '[a-z]')_$(lsb_release -cs)
else
  host_distro=all
fi
if [ -n $FRIDA_HOST ]; then
  host_arch=$(echo -n $FRIDA_HOST | sed 's,\([a-z]\+\)-\(.\+\),\2,g')
else
  host_arch=$(uname -m)
fi
host_platform_arch=${host_platform}-${host_arch}

if [ -z $FRIDA_HOST ]; then
  echo "Assuming host is $host_platform_arch Set FRIDA_HOST to override."
fi

FRIDA_BUILD="$FRIDA_ROOT/build"
FRIDA_PREFIX="$FRIDA_BUILD/frida-$host_platform_arch"

BUILDROOT="$FRIDA_BUILD/tmp-$host_platform_arch/deps"

REPO_BASE_URL="git://github.com/frida"
REPO_SUFFIX=".git"

function sed_inplace ()
{
  if [ "${build_platform}" = "mac" ]; then
    sed -i "" $*
  else
    sed -i $*
  fi
}

function strip_all ()
{
  if [ "${build_platform}" = "mac" ]; then
    strip -Sx $*
  else
    strip --strip-all $*
  fi
}

function expand_host ()
{
  case $1 in
    linux-i386)
      echo i686-pc-linux-gnu
    ;;
    linux-x86_64)
      echo x86_64-pc-linux-gnu
    ;;
    android-arm)
      echo armv7-none-linux-androideabi
    ;;
    mac-i386)
      echo i686-apple-darwin
    ;;
    mac-x86_64)
      echo x86_64-apple-darwin$(uname -r)
    ;;
    ios-arm)
      echo arm-apple-darwin
    ;;
    ios-arm64)
      echo aarch64-apple-darwin
    ;;
  esac
}

function build_toolchain ()
{
  mkdir -p "$BUILDROOT" || exit 1
  pushd "$BUILDROOT" >/dev/null || exit 1

  export PATH="$FRIDA_PREFIX/bin":$PATH
  export PKG_CONFIG="$FRIDA_PREFIX/bin/pkg-config"

  build_tarball http://ftp.gnu.org/gnu/m4/m4-1.4.16.tar.gz
  build_tarball http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
  build_tarball http://ftp.gnu.org/gnu/automake/automake-1.13.1.tar.gz
  pushd "$FRIDA_PREFIX/bin" >/dev/null || exit 1
  rm aclocal
  ln -s aclocal-1.13 aclocal
  rm automake
  ln -s automake-1.13 automake
  popd >/dev/null
  build_tarball http://gnuftp.uib.no/libtool/libtool-2.4.2.tar.gz
  build_tarball http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz --with-internal-glib
  pushd "$FRIDA_PREFIX/bin" >/dev/null || exit 1
  rm pkg-config
  ln -s *-pkg-config pkg-config
  popd >/dev/null
  build_module libffi $(expand_host $host_platform_arch)
  build_module glib
  build_module vala

  strip_all "$FRIDA_PREFIX/bin/*" 2>/dev/null

  popd >/dev/null
}

function make_toolchain_package ()
{
  local target_filename="$FRIDA_BUILD/toolchain-${build_platform}-$(date '+%Y%m%d').tar.bz2"

  local tooldir="$BUILDROOT/toolchain"
  rm -rf "$tooldir"
  mkdir "$tooldir"

  pushd "$FRIDA_PREFIX" >/dev/null || exit 1
  tar \
      -c \
      --exclude etc \
      --exclude include \
      --exclude lib \
      --exclude share/devhelp \
      --exclude share/doc \
      --exclude share/emacs \
      --exclude share/gdb \
      --exclude share/info \
      --exclude share/man \
      . | tar -C "$tooldir" -xf - || exit 1
  popd >/dev/null

  pushd "$BUILDROOT" >/dev/null || exit 1
  tar cfj "$target_filename" toolchain || exit 1
  popd >/dev/null

  rm -rf "$tooldir"
}

function build_sdk ()
{
  mkdir -p "$BUILDROOT" || exit 1
  pushd "$BUILDROOT" >/dev/null || exit 1

  [ "${host_platform_arch}" = "linux-arm" ] && build_module zlib
  case $host_platform in
    linux)
      build_bfd
      ;;
    android)
      build_iconv
      build_bfd
      ;;
  esac
  build_module libffi $(expand_host $host_platform_arch)
  build_module glib
  build_module libgee
  build_module json-glib
  build_v8

  popd >/dev/null
}

function make_sdk_package ()
{
  local target_filename="$FRIDA_BUILD/sdk-$(date '+%Y%m%d')-${host_platform}-${host_distro}-${host_arch}.tar.bz2"

  local sdkname="sdk-$host_platform_arch"
  local sdkdir="$BUILDROOT/$sdkname"
  pushd "$BUILDROOT" >/dev/null || exit 1
  rm -rf "$sdkname"
  mkdir "$sdkname"
  popd >/dev/null

  pushd "$FRIDA_PREFIX" >/dev/null || exit 1
  if [ "$host_platform" = "ios" ]; then
    cp /System/Library/Frameworks/Kernel.framework/Versions/A/Headers/mach/mach_vm.h include/frida_mach_vm.h
  fi
  tar c \
      include \
      lib/*.a \
      lib/*.la.frida.in \
      lib/glib-2.0 \
      lib/libffi* \
      lib/pkgconfig \
      share/aclocal \
      share/glib-2.0/schemas \
      share/vala \
      | tar -C "$sdkdir" -xf - || exit 1
  popd >/dev/null

  pushd "$BUILDROOT" >/dev/null || exit 1
  tar cfj "$target_filename" "$sdkname" || exit 1
  popd >/dev/null

  rm -rf "$sdkdir"
}

function build_tarball ()
{
  url=$1
  shift
  name=$(basename $url | sed -e 's,\.tar\.gz$,,')
  if [ ! -d "$name" ]; then
    echo "Building $name"
    ${download_command} $url | tar -xz ${tar_stdin} || exit 1
    pushd "$name" >/dev/null || exit 1
    ./configure $* || exit 1
    make -j8 || exit 1
    make install || exit 1
    popd >/dev/null
    rm -f "${FRIDA_PREFIX}/config.cache"
  fi
}

function build_module ()
{
  if [ ! -d "$1" ]; then
    git clone "${REPO_BASE_URL}/${1}${REPO_SUFFIX}" || exit 1
    pushd "$1" >/dev/null || exit 1
    if [ "$1" = "zlib" ]; then
      (
        source $CONFIG_SITE
        CC=${ac_tool_prefix}gcc ./configure --static --prefix=${FRIDA_PREFIX}
      )
    elif [ -f "autogen.sh" ]; then
      ./autogen.sh || exit 1
      if [ "$1" = "libffi" ]; then
        ./configure || exit 1
      fi
    else
      ./configure || exit 1
    fi
    if [ -n "$2" ]; then
      pushd "$2" >/dev/null || exit 1
    fi
    if [ "$1" = "json-glib" ]; then
      make -j8 GLIB_GENMARSHAL=glib-genmarshal GLIB_MKENUMS=glib-mkenums || exit 1
    else
      make -j8 || exit 1
    fi
    make install || exit 1
    [ -n "$2" ] && popd &>/dev/null
    popd >/dev/null
    rm -f "${FRIDA_PREFIX}/config.cache"
  fi
}

function build_iconv ()
{
  if [ ! -d "libiconv-1.14" ]; then
    curl "http://gnuftp.uib.no/libiconv/libiconv-1.14.tar.gz" | tar xz
    pushd "libiconv-1.14" >/dev/null || exit 1
    patch -p1 << EOF
--- libiconv/Makefile.in	2009-06-21 19:17:33.000000000 +0800
+++ libiconv/Makefile.in	2011-10-13 22:51:46.000000000 +0800
@@ -32,11 +32,6 @@ SHELL = /bin/sh
 all : lib/localcharset.h force
 	cd lib && \$(MAKE) all
 	cd preload && \$(MAKE) all
-	cd srclib && \$(MAKE) all
-	cd src && \$(MAKE) all
-	cd po && \$(MAKE) all
-	cd man && \$(MAKE) all
-	if test -d tests; then cd tests && \$(MAKE) all; fi
 
 lib/localcharset.h :
 	builddir="`pwd`"; cd libcharset && \$(MAKE) all && \$(MAKE) install-lib libdir="\$\$builddir/lib" includedir="\$\$builddir/lib"
@@ -52,23 +47,16 @@ install : lib/localcharset.h force
 	cd libcharset && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	cd lib && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	cd preload && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
-	cd srclib && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
-	cd src && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	if [ ! -d \$(DESTDIR)\$(includedir) ] ; then \$(mkinstalldirs) \$(DESTDIR)\$(includedir) ; fi
 	\$(INSTALL_DATA) include/iconv.h.inst \$(DESTDIR)\$(includedir)/iconv.h
-	cd po && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' datarootdir='\$(datarootdir)' datadir='\$(datadir)'
-	cd man && \$(MAKE) install prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' datarootdir='\$(datarootdir)' datadir='\$(datadir)' mandir='\$(mandir)'
 
 install-strip : lib/localcharset.h force
 	cd libcharset && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	cd lib && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	cd preload && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	cd srclib && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
-	cd src && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
 	if [ ! -d \$(DESTDIR)\$(includedir) ] ; then \$(mkinstalldirs) \$(DESTDIR)\$(includedir) ; fi
 	\$(INSTALL_DATA) include/iconv.h.inst \$(DESTDIR)\$(includedir)/iconv.h
-	cd po && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' datarootdir='\$(datarootdir)' datadir='\$(datadir)'
-	cd man && \$(MAKE) install-strip prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' datarootdir='\$(datarootdir)' datadir='\$(datadir)' mandir='\$(mandir)'
 
 installdirs : force
 	cd libcharset && \$(MAKE) installdirs prefix='\$(prefix)' exec_prefix='\$(exec_prefix)' libdir='\$(libdir)'
EOF
    FRIDA_LEGACY_AUTOTOOLS=1 ./configure --enable-static --enable-relocatable --disable-rpath || exit 1
    make -j8 || exit 1
    make install || exit 1
    popd >/dev/null
    rm -f "${FRIDA_PREFIX}/config.cache"
  fi
}

function build_bfd ()
{
  if [ ! -d "binutils-2.23.2" ]; then
    curl "http://gnuftp.uib.no/binutils/binutils-2.23.2.tar.bz2" | tar xj
    pushd "binutils-2.23.2" >/dev/null || exit 1
    patch -p1 << EOF
diff -Nur binutils-2.23.2-old/libiberty/getpagesize.c binutils-2.23.2/libiberty/getpagesize.c
--- binutils-2.23.2-old/libiberty/getpagesize.c	2005-03-28 04:09:01.000000000 +0200
+++ binutils-2.23.2/libiberty/getpagesize.c	2013-10-24 22:45:24.000000000 +0200
@@ -20,6 +20,7 @@
 
 */
 
+#ifndef ANDROID
 #ifndef VMS
 
 #include "config.h"
@@ -88,3 +89,4 @@
 }
 
 #endif /* VMS */
+#endif /* ANDROID */
diff -Nur binutils-2.23.2-old/bfd/archive.c binutils-2.23.2/bfd/archive.c
--- binutils-2.23.2-old/bfd/archive.c	2013-03-25 09:06:19.000000000 +0100
+++ binutils-2.23.2/bfd/archive.c	2013-10-24 21:48:30.000000000 +0200
@@ -1863,7 +1863,9 @@
     {
       /* Assume we just "made" the member, and fake it.  */
       struct bfd_in_memory *bim = (struct bfd_in_memory *) member->iostream;
-      time (&status.st_mtime);
+      time_t t;
+      time (&t);
+      status.st_mtime = t;
       status.st_uid = getuid ();
       status.st_gid = getgid ();
       status.st_mode = 0644;
EOF

    pushd libiberty >/dev/null || exit 1
    ./configure || exit 1
    make -j8 || exit 1
    popd >/dev/null

    pushd bfd >/dev/null || exit 1
    ./configure || exit 1
    make -j8 || exit 1
    make install || exit 1
    mkdir tmp >/dev/null
    pushd tmp >/dev/null
    $AR x ../../libiberty/libiberty.a
    $AR x ../libbfd.a
    $AR r ../libbfd-full.a *.o
    $RANLIB ../libbfd-full.a
    install -m 644 ../libbfd-full.a $FRIDA_PREFIX/lib/libbfd.a
    popd >/dev/null
    rm -rf tmp
    popd >/dev/null

    popd >/dev/null
    rm -f "${FRIDA_PREFIX}/config.cache"
  fi
}

function build_v8_generic ()
{
  if [ "${build_platform}" = "mac" ]; then
    case $host_platform in
      android)
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
          MACOSX_DEPLOYMENT_TARGET="" \
          CXX="$CXX" \
          CXX_host="$(xcrun --sdk macosx10.9 -f clang++) -stdlib=libc++" \
          CXX_target="$CXX" \
          LINK="$CXX" \
          LINK_host="$(xcrun --sdk macosx10.9 -f clang++) -stdlib=libc++" \
          CFLAGS="" \
          CXXFLAGS="" \
          CPPFLAGS="" \
          LDFLAGS="" \
          make $target GYPFLAGS="$flags" V=1
      ;;
      *)
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
          MACOSX_DEPLOYMENT_TARGET="" \
          CXX="$CXX -stdlib=libc++" \
          CXX_host="$CXX -stdlib=libc++" \
          CXX_target="$CXX -stdlib=libc++" \
          LINK="$CXX -stdlib=libc++" \
          make $target GYPFLAGS="$flags" V=1
      ;;
    esac
  else
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
      CXX_host="$CXX" \
      CXX_target="$CXX" \
      LINK="$CXX" \
      make $target GYPFLAGS="$flags" V=1
  fi
}

function build_v8_linux_arm ()
{
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    CC=arm-linux-gnueabi-gcc \
    CXX=arm-linux-gnueabi-g++ \
    LINK=arm-linux-gnueabi-g++ \
    CFLAGS="" \
    CXXFLAGS="" \
    LDFLAGS="" \
    make arm.release V=1
}

function build_v8 ()
{
  if [ ! -d v8 ]; then
    git clone "${REPO_BASE_URL}/v8${REPO_SUFFIX}" || exit 1
    pushd v8 >/dev/null || exit 1

    flavor_prefix=
    if [ "$host_platform_arch" = "linux-arm" ]; then
      build_v8_linux_arm
      find out -name "*.target-arm.mk" -exec sed -i -e "s,-m32,,g" {} \;
      build_v8_linux_arm || exit 1
      arch=arm
    else
      flags="-D werror='' -Dv8_enable_gdbjit=0 -Dv8_enable_i18n_support=0"
      case $host_platform_arch in
        linux-i386)
          arch=ia32
          flags="-f make-linux -D host_os=$build_platform $flags"
        ;;
        linux-x86_64)
          arch=x64
          flags="-f make-linux -D host_os=$build_platform $flags"
        ;;
        android-arm)
          flavor_prefix=android_
          arch=arm
          flags="-f make-android -D host_os=$build_platform -D clang=1 $flags"
        ;;
        mac-i386)
          arch=ia32
          flags="-f make-mac -D host_os=$build_platform -D mac_deployment_target=10.7 -D clang=1 $flags"
        ;;
        mac-x86_64)
          arch=x64
          flags="-f make-mac -D host_os=$build_platform -D mac_deployment_target=10.7 -D clang=1 $flags"
        ;;
        ios-arm)
          arch=arm
          flags="-f make-mac -D host_os=$build_platform -D mac_deployment_target=10.7 -D ios_deployment_target=7.0 -D clang=1 $flags"
        ;;
        ios-arm64)
          arch=arm64
          flags="-f make-mac -D host_os=$build_platform -D mac_deployment_target=10.7 -D ios_deployment_target=7.0 -D clang=1 $flags"
        ;;
        *)
          echo "FIXME"
          exit 1
        ;;
      esac
      target=${flavor_prefix}${arch}.release

      build_v8_generic || exit 1
    fi

    case $host_platform in
      linux)
        outdir=out/$target/obj.target/tools/gyp
      ;;
      *)
        outdir=out/$target
      ;;
    esac

    install -d $FRIDA_PREFIX/include
    install -m 644 include/* $FRIDA_PREFIX/include

    install -d $FRIDA_PREFIX/lib
    install -m 644 $outdir/libv8_base.${arch}.a $FRIDA_PREFIX/lib
    install -m 644 $outdir/libv8_snapshot.a $FRIDA_PREFIX/lib

    install -d $FRIDA_PREFIX/lib/pkgconfig
    cat > $FRIDA_PREFIX/lib/pkgconfig/v8.pc << EOF
prefix=\${frida_sdk_prefix}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: V8
Description: V8 JavaScript Engine
Version: 3.26.6.1
Libs: -L\${libdir} -lv8_base.${arch} -lv8_snapshot
Cflags: -I\${includedir}
EOF

    popd >/dev/null
  fi
}

function apply_fixups ()
{
  for file in $(find "$FRIDA_PREFIX" -type f); do
    if grep -q "$FRIDA_PREFIX" $file; then
      if echo "$file" | grep -Eq "\\.pm$|aclocal.*|autoconf|autoheader|autom4te.*|automake.*|autoreconf|autoscan|autoupdate|ifnames|libtoolize"; then
        newname="$file.frida.in"
        mv "$file" "$newname"
        sed_inplace -e "s,$FRIDA_PREFIX,@FRIDA_TOOLROOT@,g" "$newname"
      elif echo "$file" | grep -Eq "\\.la$"; then
        newname="$file.frida.in"
        mv "$file" "$newname"
        sed_inplace -e "s,$FRIDA_PREFIX,@FRIDA_SDKROOT@,g" "$newname"
      elif echo "$file" | grep -Eq "\\.pc$"; then
        sed_inplace -e "s,$FRIDA_PREFIX,\${frida_sdk_prefix},g" "$file"
      fi
    fi
  done
}

case $1 in
  clean)
    set -x
    rm -rf "$BUILDROOT"
    rm -rf "$FRIDA_PREFIX"
    mkdir -p "$FRIDA_PREFIX/share/aclocal"
    set +x
  ;;
  toolchain)
    set -x
    build_toolchain
    apply_fixups
    make_toolchain_package
    set +x
  ;;
  sdk)
    set -x
    build_sdk
    apply_fixups
    make_sdk_package
    set +x
  ;;
  *)
    echo "Usage: $0 [clean|toolchain|sdk]" > /dev/stderr
    exit 1
  ;;
esac

echo "All done."
