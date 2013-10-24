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

build_os=$(uname -s | tr '[A-Z]' '[a-z]')
[ "$build_os" = 'darwin' ] && build_os=mac

case $build_os in
  linux)
    download_command="wget -O - -nv"
    tar_stdin=""
    ;;
  mac)
    download_command="curl -sS"
    tar_stdin="-"
    ;;
  *)
    echo "Could not determine build OS" > /dev/stderr
    exit 1
esac

if [ -z $FRIDA_TARGET ]; then
  if [ $build_os = 'linux' ]; then
    case $(uname -m) in
      x86_64)
        FRIDA_TARGET=linux-x86_64
      ;;
      i686)
        FRIDA_TARGET=linux-x86_32
      ;;
      *)
      echo "Could not automatically determine architecture" > /dev/stderr
      exit 1
    esac
  else
    FRIDA_TARGET=mac64
  fi
  echo "Assuming target is $FRIDA_TARGET. Set FRIDA_TARGET to override."
fi

FRIDA_BUILD="$FRIDA_ROOT/build"
FRIDA_PREFIX="$FRIDA_BUILD/frida-$FRIDA_TARGET"

BUILDROOT="$FRIDA_BUILD/tmp-$FRIDA_TARGET/deps"

REPO_BASE_URL="git://gitorious.org/frida"
REPO_SUFFIX=".git"

function sed_inplace ()
{
  if [ "${build_os}" = "mac" ]; then
    sed -i "" $*
  else
    sed -i $*
  fi
}

function strip_all ()
{
  if [ "${build_os}" = "mac" ]; then
    strip -Sx $*
  else
    strip --strip-all $*
  fi
}

function expand_target ()
{
  case $1 in
    linux-x86_32)
      echo i686-pc-linux-gnu
    ;;
    linux-x86_64)
      echo x86_64-pc-linux-gnu
    ;;
    android)
      echo armv7-none-linux-androideabi
    ;;
    mac32)
      echo i686-apple-darwin
    ;;
    mac64)
      echo x86_64-apple-darwin12.3.0
    ;;
    ios)
      echo arm-apple-darwin
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
  build_module libffi $(expand_target $FRIDA_TARGET)
  build_module glib
  build_module vala

  strip_all "$FRIDA_PREFIX/bin/*" 2>/dev/null

  popd >/dev/null
}

function make_toolchain_package ()
{
  local target_filename="$FRIDA_BUILD/toolchain-${build_os}-$(date '+%Y%m%d').tar.bz2"

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

  [ "${FRIDA_TARGET}" = "linux-arm" ] && build_module zlib
  case $FRIDA_TARGET in
    linux-*)
      build_bfd
      ;;
    android)
      build_iconv
      build_bfd
      ;;
  esac
  build_module libffi $(expand_target $FRIDA_TARGET)
  build_module glib
  build_module libgee
  build_module json-glib
  build_v8

  popd >/dev/null
}

function make_sdk_package ()
{
  local target_filename="$FRIDA_BUILD/sdk-$FRIDA_TARGET-$(date '+%Y%m%d').tar.bz2"

  local sdkname="sdk-$FRIDA_TARGET"
  local sdkdir="$BUILDROOT/$sdkname"
  pushd "$BUILDROOT" >/dev/null || exit 1
  rm -rf "$sdkname"
  mkdir "$sdkname"
  popd >/dev/null

  pushd "$FRIDA_PREFIX" >/dev/null || exit 1
  if [ "$FRIDA_TARGET" = "ios" ]; then
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
    elif [ "$1" = "libffi" -a "$FRIDA_TARGET" = "ios" ]; then
      CC="${IOS_DEVROOT}/usr/bin/llvm-gcc-4.2" ./configure || exit 1
    elif [ -f "autogen.sh" ]; then
      ./autogen.sh || exit 1
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
    curl "http://gnuftp.uib.no/libiconv/libiconv-1.14.tar.gz" | tar x
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
    curl "http://gnuftp.uib.no/binutils/binutils-2.23.2.tar.bz2" | tar x
    pushd "binutils-2.23.2/bfd" >/dev/null || exit 1
    patch -p2 << EOF
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
    ./configure || exit 1
    make -j8 || exit 1
    make install || exit 1
    popd >/dev/null
    rm -f "${FRIDA_PREFIX}/config.cache"
  fi
}

function build_v8_generic ()
{
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" MACOSX_DEPLOYMENT_TARGET="" LD="$CXX" make $target GYPFLAGS="$flags" V=1
}

function build_v8_ios ()
{
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" MACOSX_DEPLOYMENT_TARGET="" CC="${IOS_DEVROOT}/usr/bin/llvm-gcc-4.2" CXX="${IOS_DEVROOT}/usr/bin/llvm-g++-4.2" OBJC="${IOS_DEVROOT}/usr/bin/llvm-gcc-4.2" LD="${IOS_DEVROOT}/usr/bin/llvm-g++-4.2" make $target GYPFLAGS="$flags" V=1
}

function build_v8_linux_arm ()
{
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" CC=arm-linux-gnueabi-gcc CXX=arm-linux-gnueabi-g++ LINK=arm-linux-gnueabi-g++ CFLAGS="" CXXFLAGS="" LDFLAGS="" make arm.release V=1
}

function build_v8 ()
{
  if [ ! -d v8 ]; then
    git clone "${REPO_BASE_URL}/v8${REPO_SUFFIX}" || exit 1
    pushd v8 >/dev/null || exit 1

    if [ "$FRIDA_TARGET" = "mac64" ]; then
      sed_inplace -e "s,\['i386'\]),['x86_64']),g" build/gyp/pylib/gyp/xcode_emulation.py
    fi

    flavor=v8_snapshot
    if [ "$FRIDA_TARGET" = "linux-arm" ]; then
      build_v8_linux_arm
      find out -name "*.target-arm.mk" -exec sed -i -e "s,-m32,,g" {} \;
      build_v8_linux_arm || exit 1
      target=arm.release
    else
      case $FRIDA_TARGET in
        linux-x86_32)
          target=ia32.release
          flags="-f make-linux -D host_os=$build_os"
        ;;
        linux-x86_64)
          target=x64.release
          flags="-f make-linux -D host_os=$build_os"
        ;;
        android)
          target=android_arm.release
          flags="-f make-linux -D host_os=$build_os -D v8_use_snapshot='false'"
          flavor=v8_nosnapshot
        ;;
        mac32)
          target=ia32.release
          flags="-f make-mac -D host_os=$build_os"
        ;;
        mac64)
          target=x64.release
          flags="-f make-mac -D host_os=$build_os"
        ;;
        ios)
          target=arm.release
          flags="-f make-mac -D host_os=$build_os"
          flavor=v8_nosnapshot
        ;;
        *)
          echo "FIXME"
          exit 1
        ;;
      esac
      if [ "$FRIDA_TARGET" = "ios" ]; then
        build_v8_ios || exit 1
      else
        build_v8_generic || exit 1
      fi
    fi

    case $FRIDA_TARGET in
      linux-*|android)
        outdir=out/$target/obj.target/tools/gyp
      ;;
      *)
        outdir=out/$target
      ;;
    esac

    install -d $FRIDA_PREFIX/include
    install -m 644 include/* $FRIDA_PREFIX/include

    install -d $FRIDA_PREFIX/lib
    install -m 644 $outdir/libv8_base.a $FRIDA_PREFIX/lib
    install -m 644 $outdir/lib${flavor}.a $FRIDA_PREFIX/lib

    install -d $FRIDA_PREFIX/lib/pkgconfig
    cat > $FRIDA_PREFIX/lib/pkgconfig/v8.pc << EOF
prefix=\${frida_sdk_prefix}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: V8
Description: V8 JavaScript Engine
Version: 3.13.3.1
Libs: -L\${libdir} -lv8_base -l${flavor}
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
