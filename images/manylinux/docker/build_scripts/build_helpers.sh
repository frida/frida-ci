#!/bin/bash

build_perl ()
{
  check_var $PERL_ROOT
  check_var $PERL_HASH
  # Can't use curl here because we don't have it yet, perl must be prefetched
  check_required_source ${PERL_ROOT}.tar.gz
  check_sha256sum ${PERL_ROOT}.tar.gz ${PERL_HASH}

  tar -xzf ${PERL_ROOT}.tar.gz
  (cd ${PERL_ROOT} && do_perl_build)
  rm -rf ${PERL_ROOT} ${PERL_ROOT}.tar.gz
}

do_perl_build ()
{
  sh Configure \
      -des \
      -Dprefix=$DEVTOOLS_PREFIX \
      -Dcc=$DEVTOOLS_PREFIX/bin/gcc \
      -Accflags="$CFLAGS" \
      -Aldflags="-static-libgcc -fuse-ld=gold $LDFLAGS" \
      > /dev/null
  make -j$CORES > /dev/null
  make install-strip > /dev/null
}

build_openssl ()
{
  check_var $OPENSSL_ROOT
  check_var $OPENSSL_HASH
  # Can't use curl here because we don't have it yet, OpenSSL must be prefetched
  check_required_source ${OPENSSL_ROOT}.tar.gz
  check_sha256sum ${OPENSSL_ROOT}.tar.gz ${OPENSSL_HASH}

  for arch in 64 32; do
    tar -xzf ${OPENSSL_ROOT}.tar.gz
    (cd ${OPENSSL_ROOT} && do_openssl_build $arch)
    rm -rf ${OPENSSL_ROOT}
  done

  rm -f ${OPENSSL_ROOT}.tar.gz
}

do_openssl_build ()
{
  local arch=$1
  check_var $arch

  if [ $arch = "32" ]; then
    local arch_flags="linux-x86"
  else
    local arch_flags="linux-x86_64"
  fi

  __CNF_CFLAGS="$CFLAGS" __CNF_LDFLAGS="$LDFLAGS" __CNF_LDLIBS="-ldl -lpthread" perl Configure \
      --prefix=$DEVTOOLS_PREFIX \
      --libdir=$DEVTOOLS_PREFIX/$(print_libdir_name_for $arch) \
      --openssldir=/etc/ssl \
      no-shared \
      no-engine \
      $arch_flags \
      > /dev/null
  make -j$CORES > /dev/null
  make install_sw > /dev/null
}

build_curl ()
{
  check_var $CURL_ROOT
  check_var $CURL_HASH
  # Can't use curl here because we don't have it yet...we are building it. It must be prefetched
  check_required_source ${CURL_ROOT}.tar.gz
  check_sha256sum ${CURL_ROOT}.tar.gz ${CURL_HASH}

  tar -xf ${CURL_ROOT}.tar.gz
  (cd curl-*/ && do_curl_build)
  rm -rf curl-*
}

do_curl_build ()
{
  PKG_CONFIG="/usr/bin/pkg-config --static" ./configure \
      $(print_build_switch_for 64) \
      --prefix=$DEVTOOLS_PREFIX \
      --libdir=$DEVTOOLS_PREFIX/lib64 \
      --with-ssl=$DEVTOOLS_PREFIX \
      --disable-shared \
      > /dev/null
  make -j$CORES > /dev/null
  make install-strip > /dev/null
}

build_m4 ()
{
  check_var $M4_ROOT
  check_var $M4_HASH
  check_var $M4_DOWNLOAD_URL

  fetch_source ${M4_ROOT}.tar.gz ${M4_DOWNLOAD_URL}
  check_sha256sum ${M4_ROOT}.tar.gz ${M4_HASH}
  tar -xf ${M4_ROOT}.tar.gz
  (cd ${M4_ROOT} && do_standard_install $(print_build_switch_for 64))
  rm -rf ${M4_ROOT} ${M4_ROOT}.tar.gz
}

build_autoconf ()
{
  check_var $AUTOCONF_ROOT
  check_var $AUTOCONF_HASH
  check_var $AUTOCONF_DOWNLOAD_URL

  fetch_source ${AUTOCONF_ROOT}.tar.gz ${AUTOCONF_DOWNLOAD_URL}
  check_sha256sum ${AUTOCONF_ROOT}.tar.gz ${AUTOCONF_HASH}
  tar -xf ${AUTOCONF_ROOT}.tar.gz
  (cd ${AUTOCONF_ROOT} && do_standard_install $(print_build_switch_for 64))
  rm -rf ${AUTOCONF_ROOT} ${AUTOCONF_ROOT}.tar.gz
}

build_automake ()
{
  check_var $AUTOMAKE_ROOT
  check_var $AUTOMAKE_HASH
  check_var $AUTOMAKE_DOWNLOAD_URL

  fetch_source ${AUTOMAKE_ROOT}.tar.gz ${AUTOMAKE_DOWNLOAD_URL}
  check_sha256sum ${AUTOMAKE_ROOT}.tar.gz ${AUTOMAKE_HASH}
  tar -xf ${AUTOMAKE_ROOT}.tar.gz
  (cd ${AUTOMAKE_ROOT} && do_standard_install $(print_build_switch_for 64))
  rm -rf ${AUTOMAKE_ROOT} ${AUTOMAKE_ROOT}.tar.gz
}

build_libtool ()
{
  check_var $LIBTOOL_ROOT
  check_var $LIBTOOL_HASH
  check_var $LIBTOOL_DOWNLOAD_URL

  fetch_source ${LIBTOOL_ROOT}.tar.gz ${LIBTOOL_DOWNLOAD_URL}
  check_sha256sum ${LIBTOOL_ROOT}.tar.gz $LIBTOOL_HASH
  tar -xf ${LIBTOOL_ROOT}.tar.gz
  (cd ${LIBTOOL_ROOT} && do_standard_install \
      $(print_build_switch_for 64) \
      --libdir=$DEVTOOLS_PREFIX/lib64)
  rm -rf ${LIBTOOL_ROOT} ${LIBTOOL_ROOT}.tar.gz
}

build_patchelf ()
{
  curl -fsSL -o patchelf.tar.gz https://github.com/NixOS/patchelf/archive/$PATCHELF_VERSION.tar.gz
  check_sha256sum patchelf.tar.gz $PATCHELF_HASH
  tar -xzf patchelf.tar.gz
  (cd patchelf-$PATCHELF_VERSION \
      && ./bootstrap.sh \
      && do_standard_install $(print_build_switch_for 64))
  rm -rf patchelf.tar.gz patchelf-$PATCHELF_VERSION
}

build_xz ()
{
  check_var $XZ_ROOT
  check_var $XZ_HASH
  check_var $XZ_DOWNLOAD_URL

  fetch_source ${XZ_ROOT}.tar.gz ${XZ_DOWNLOAD_URL}
  check_sha256sum ${XZ_ROOT}.tar.gz $XZ_HASH

  for arch in 64 32; do
    tar -xf ${XZ_ROOT}.tar.gz
    pushd ${XZ_ROOT}

    do_xz_build $arch

    popd
    rm -rf ${XZ_ROOT}
  done

  rm -f ${XZ_ROOT}.tar.gz
}

do_xz_build ()
{
  local arch=$1
  check_var $arch

  CPPFLAGS="-m${arch}" CFLAGS="-m${arch} $CFLAGS" LDFLAGS="-m${arch} $LDFLAGS" do_standard_install \
      $(print_build_switch_for $arch) \
      --libdir=$DEVTOOLS_PREFIX/$(print_libdir_name_for $arch) \
      --disable-shared
}

build_tar ()
{
  check_var $TAR_ROOT
  check_var $TAR_HASH
  check_var $TAR_DOWNLOAD_URL

  fetch_source ${TAR_ROOT}.tar.gz ${TAR_DOWNLOAD_URL}
  check_sha256sum ${TAR_ROOT}.tar.gz $TAR_HASH
  tar -xf ${TAR_ROOT}.tar.gz
  (cd ${TAR_ROOT} && do_standard_install $(print_build_switch_for 64))
  rm -rf ${TAR_ROOT} ${TAR_ROOT}.tar.gz
}

build_sqlite ()
{
  check_var $SQLITE_AUTOCONF_VERSION
  check_var $SQLITE_AUTOCONF_HASH
  check_var $SQLITE_AUTOCONF_DOWNLOAD_URL

  curl -fsSLO $SQLITE_AUTOCONF_DOWNLOAD_URL/$SQLITE_AUTOCONF_VERSION.tar.gz
  check_sha256sum $SQLITE_AUTOCONF_VERSION.tar.gz $SQLITE_AUTOCONF_HASH

  for arch in 64 32; do
    tar xf $SQLITE_AUTOCONF_VERSION.tar.gz
    pushd $SQLITE_AUTOCONF_VERSION

    do_sqlite_build $arch

    popd
    rm -rf $SQLITE_AUTOCONF_VERSION
  done

  rm -f $SQLITE_AUTOCONF_VERSION.tar.gz
}

do_sqlite_build ()
{
  local arch=$1
  check_var $arch

  CPPFLAGS="-m${arch}" CFLAGS="-m${arch} $CFLAGS" LDFLAGS="-m${arch} $LDFLAGS" do_standard_install \
      $(print_build_switch_for $arch) \
      --libdir=$DEVTOOLS_PREFIX/$(print_libdir_name_for $arch) \
      --disable-shared
}

build_libffi ()
{
  check_var $LIBFFI_ROOT
  check_var $LIBFFI_HASH
  check_var $LIBFFI_DOWNLOAD_URL

  fetch_source ${LIBFFI_ROOT}.tar.gz ${LIBFFI_DOWNLOAD_URL}
  check_sha256sum ${LIBFFI_ROOT}.tar.gz ${LIBFFI_HASH}

  for arch in 64 32; do
    tar -xf ${LIBFFI_ROOT}.tar.gz
    pushd ${LIBFFI_ROOT}

    patch -p1 < ${MY_DIR}/patches/libffi.patch
    autoreconf -if

    do_libffi_build $arch

    popd
    rm -rf ${LIBFFI_ROOT}
  done

  rm -f ${LIBFFI_ROOT}.tar.gz
}

do_libffi_build ()
{
  local arch=$1
  check_var $arch

  CPPFLAGS="-m${arch}" CFLAGS="-m${arch} $CFLAGS" LDFLAGS="-m${arch} $LDFLAGS" do_standard_install \
      $(print_build_switch_for $arch) \
      --includedir=$DEVTOOLS_PREFIX/include/libffi-$arch \
      --libdir=$DEVTOOLS_PREFIX/$(print_libdir_name_for $arch) \
      --disable-shared
}

build_libxcrypt ()
{
  check_var $LIBXCRYPT_DOWNLOAD_URL
  check_var $LIBXCRYPT_VERSION

  curl -fsSLO "$LIBXCRYPT_DOWNLOAD_URL"/v"$LIBXCRYPT_VERSION"
  check_sha256sum "v$LIBXCRYPT_VERSION" "$LIBXCRYPT_HASH"

  # Delete GLIBC version headers and libraries
  rm -rf /usr/include/crypt.h
  rm -rf /usr/lib/libcrypt.a /usr/lib/libcrypt.so
  rm -rf /usr/lib64/libcrypt.a /usr/lib64/libcrypt.so

  for arch in 64 32; do
    tar xf v$LIBXCRYPT_VERSION
    pushd libxcrypt-$LIBXCRYPT_VERSION

    do_libxcrypt_build $arch

    popd
    rm -rf libxcrypt-$LIBXCRYPT_VERSION
  done

  rm -f v$LIBXCRYPT_VERSION
}

do_libxcrypt_build ()
{
  local arch=$1
  check_var $arch

  ./autogen.sh

  CPPFLAGS="-m${arch}" CFLAGS="-m${arch} $CFLAGS" LDFLAGS="-m${arch} $LDFLAGS" ./configure \
      $(print_build_switch_for $arch) \
      --prefix=/usr \
      --libdir=/usr/$(print_libdir_name_for $arch) \
      --disable-obsolete-api \
      --enable-hashes=all \
      --disable-shared \
      > /dev/null
  make -j$CORES > /dev/null
  make install-strip > /dev/null
}

build_openssh ()
{
  check_var $OPENSSH_ROOT
  check_var $OPENSSH_HASH
  check_var $OPENSSH_DOWNLOAD_URL

  fetch_source ${OPENSSH_ROOT}.tar.gz ${OPENSSH_DOWNLOAD_URL}
  check_sha256sum ${OPENSSH_ROOT}.tar.gz ${OPENSSH_HASH}
  tar -xf ${OPENSSH_ROOT}.tar.gz
  (cd ${OPENSSH_ROOT} && do_openssh_build)
  rm -rf ${OPENSSH_ROOT} ${OPENSSH_ROOT}.tar.gz
}

do_openssh_build ()
{
  LDFLAGS="$LDFLAGS -pthread" ./configure \
      $(print_build_switch_for 64) \
      --prefix=$DEVTOOLS_PREFIX \
      --with-ssl-dir=$DEVTOOLS_PREFIX > /dev/null
  make -j$CORES > /dev/null
  make install > /dev/null
  strip --strip-all $DEVTOOLS_PREFIX/bin/ssh*
  rm -rf $DEVTOOLS_PREFIX/sbin/ $DEVTOOLS_PREFIX/libexec/{sftp,ssh}*
}

build_git ()
{
  check_var $GIT_ROOT
  check_var $GIT_HASH
  check_var $GIT_DOWNLOAD_URL

  fetch_source v${GIT_ROOT}.tar.gz ${GIT_DOWNLOAD_URL}
  check_sha256sum v${GIT_ROOT}.tar.gz ${GIT_HASH}
  tar -xzf v${GIT_ROOT}.tar.gz
  (cd git-${GIT_ROOT} \
      && make -j$CORES install \
          prefix=$DEVTOOLS_PREFIX \
          CC="$CC" \
          CPPFLAGS="-I$DEVTOOLS_PREFIX/include" \
          CFLAGS="$CFLAGS" \
          LDFLAGS="$LDFLAGS -L$DEVTOOLS_PREFIX/lib64" \
          > /dev/null)
  strip --strip-all $DEVTOOLS_PREFIX/bin/git{,-receive-pack,-shell,-upload-archive,-upload-pack}
  rm -rf git-${GIT_ROOT} v${GIT_ROOT}.tar.gz
}

build_cpythons ()
{
  # Import public keys used to verify downloaded Python source tarballs.
  # https://www.python.org/static/files/pubkeys.txt
  gpg --import ${MY_DIR}/cpython-pubkeys.txt
  # Add version 3.8 release manager's key
  gpg --import ${MY_DIR}/ambv-pubkey.txt
  for py_ver in $@; do
    build_cpython $py_ver
  done
  # Remove GPG hidden directory.
  rm -rf /root/.gnupg/
}

build_cpython ()
{
  local py_ver=$1
  check_var $py_ver
  check_var $PYTHON_DOWNLOAD_URL

  local py_dist_dir=$(pyver_dist_dir $py_ver)
  curl -fsSLO $PYTHON_DOWNLOAD_URL/$py_dist_dir/Python-$py_ver.tgz
  curl -fsSLO $PYTHON_DOWNLOAD_URL/$py_dist_dir/Python-$py_ver.tgz.asc
  gpg --verify --no-auto-key-locate Python-$py_ver.tgz.asc
  for arch in 64 32; do
    if [ $(lex_pyver $py_ver) -lt $(lex_pyver 3.3) ]; then
      do_cpython_build $py_ver ucs4 $arch
    else
      do_cpython_build $py_ver none $arch
    fi
  done
  rm -f Python-$py_ver.tgz
  rm -f Python-$py_ver.tgz.asc
}

do_cpython_build ()
{
  local py_ver=$1
  check_var $py_ver
  local ucs_setting=$2
  check_var $ucs_setting
  local arch=$3
  check_var $arch

  tar -xzf Python-$py_ver.tgz
  pushd Python-$py_ver

  if [ "$ucs_setting" = "none" ]; then
    local unicode_flags=""
    local dir_suffix=""
  else
    local unicode_flags="--enable-unicode=$ucs_setting"
    local dir_suffix="-$ucs_setting"
  fi

  local prefix="/opt/_internal/cpython-${arch}-${py_ver}${dir_suffix}"
  mkdir -p ${prefix}/lib

  local libdir_name=$(print_libdir_name_for $arch)
  local cppflags="-m${arch} -I$DEVTOOLS_PREFIX/include -I$DEVTOOLS_PREFIX/libffi-$arch"
  local cflags="-m${arch} $CFLAGS"
  local ldflags="-m${arch} $LDFLAGS -L$DEVTOOLS_PREFIX/$libdir_name -L/usr/$libdir_name"
  local pc_path="$DEVTOOLS_PREFIX/$libdir_name/pkgconfig"

  CPPFLAGS="$cppflags" \
      CFLAGS="$cflags" \
      LDFLAGS="$ldflags" \
      PKG_CONFIG_PATH="$pc_path" \
      ./configure \
          $(print_build_switch_for $arch) \
          --prefix=${prefix} \
          --disable-shared \
          --with-system-ffi \
          $unicode_flags \
          > /dev/null
  make -j$CORES > /dev/null
  make install > /dev/null

  popd

  rm -rf Python-$py_ver
  # Some python's install as bin/python3. Make them available as
  # bin/python.
  if [ -e ${prefix}/bin/python3 ]; then
    ln -s python3 ${prefix}/bin/python
  fi
  ${prefix}/bin/python -m ensurepip

  if [ -e ${prefix}/bin/pip3 ] && [ ! -e ${prefix}/bin/pip ]; then
    ln -s pip3 ${prefix}/bin/pip
  fi
  # Since we fall back on a canned copy of pip, we might not have
  # the latest pip and friends. Upgrade them to make sure.
  if [ "${py_ver:0:1}" == "2" ]; then
    ${prefix}/bin/pip install -U --require-hashes -r ${MY_DIR}/py27-requirements.txt
  else
    ${prefix}/bin/pip install -U --require-hashes -r ${MY_DIR}/requirements.txt
  fi
  local abi_tag=$(${prefix}/bin/python ${MY_DIR}/python-tag-abi-tag.py)
  ln -s ${prefix} /opt/python-${arch}/${abi_tag}
}

lex_pyver ()
{
  # Echoes Python version string padded with zeros
  # Thus:
  # 3.2.1 -> 003002001
  # 3     -> 003000000
  echo $1 | awk -F "." '{ printf "%03d%03d%03d", $1, $2, $3; }'
}

pyver_dist_dir ()
{
  # Echoes the dist directory name of given pyver, removing alpha/beta prerelease
  # Thus:
  # 3.2.1   -> 3.2.1
  # 3.7.0b4 -> 3.7.0
  echo $1 | awk -F "." '{ printf "%d.%d.%d", $1, $2, $3; }'
}

build_nodes ()
{
  check_var $NODE_ROOT
  check_var $NODE_HASH
  check_var $NODE_DOWNLOAD_URL

  fetch_source ${NODE_ROOT}.tar.gz ${NODE_DOWNLOAD_URL}
  check_sha256sum ${NODE_ROOT}.tar.gz ${NODE_HASH}

  for arch in 64 32; do
    tar -xf ${NODE_ROOT}.tar.gz
    pushd ${NODE_ROOT}

    patch -p1 < ${MY_DIR}/patches/node.patch

    PATH="/opt/python-64/cp38-cp38/bin:$PATH" do_node_build $arch

    popd
    rm -rf ${NODE_ROOT}
  done

  rm -f ${NODE_ROOT}.tar.gz
}

do_node_build ()
{
  local arch=$1
  check_var $arch

  local prefix="/opt/node-$arch"

  if [ $arch = "32" ]; then
    local arch_flags="--dest-cpu=ia32"
  else
    local arch_flags=""
  fi

  ./configure \
      --prefix=$prefix \
      --partly-static \
      $arch_flags \
      > /dev/null
  make -j$CORES > /dev/null
  make install > /dev/null
  strip --strip-all $prefix/bin/node
}

check_var ()
{
  if [ -z "$1" ]; then
    echo "required variable not defined"
    exit 1
  fi
}

check_required_source ()
{
  local file=$1
  check_var $file
  if [ ! -f $file ]; then
    echo "Required source archive must be prefetched to docker/sources/ with prefetch.sh: $file"
    return 1
  fi
}

fetch_source ()
{
  # This is called both inside and outside the build context (e.g. in Travis) to prefetch
  # source tarballs, where curl exists (and works)
  local file=$1
  check_var $file
  local url=$2
  check_var $url

  if [ -f ${file} ]; then
    echo "${file} exists, skipping fetch"
  else
    curl -fsSL -o ${file} ${url}/${file}
  fi
}

check_sha256sum ()
{
  local fname=$1
  check_var $fname
  local sha256=$2
  check_var $sha256

  echo "${sha256}  ${fname}" > ${fname}.sha256
  sha256sum -c ${fname}.sha256
  rm -f ${fname}.sha256
}

do_standard_install ()
{
  ./configure --prefix=$DEVTOOLS_PREFIX "$@" > /dev/null
  make -j$CORES > /dev/null
  make install-strip > /dev/null
}

print_build_switch_for ()
{
  local arch=$1
  check_var $arch

  local build=$(rpm --eval '%{_target_platform}')

  if [ $arch = "32" ]; then
    echo "--build=$(echo $build | sed -e 's,^x86_64,i686,')"
  else
    echo "--build=$build"
  fi
}

print_libdir_name_for ()
{
  local arch=$1
  check_var $arch

  if [ $arch = "32" ]; then
    echo lib
  else
    echo lib64
  fi
}
