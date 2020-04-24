PERL_ROOT=perl-5.30.2
PERL_HASH=66db7df8a91979eb576fac91743644da878244cf8ee152f02cd6f5cd7a731689
PERL_DOWNLOAD_URL=https://www.cpan.org/src/5.0

OPENSSL_ROOT=openssl-1.1.1f
OPENSSL_HASH=186c6bfe6ecfba7a5b48c47f8a1673d0f3b0e5ba2e25602dd23b629975da3f35
OPENSSL_DOWNLOAD_URL=https://www.openssl.org/source

CURL_ROOT=curl-7.69.1
CURL_HASH=01ae0c123dee45b01bbaef94c0bc00ed2aec89cb2ee0fd598e0d302a6b5e0a98
CURL_DOWNLOAD_URL=https://curl.haxx.se/download

M4_ROOT=m4-1.4.18
M4_HASH=ab2633921a5cd38e48797bf5521ad259bdc4b979078034a3b790d7fec5493fab
M4_DOWNLOAD_URL=https://ftp.gnu.org/gnu/m4
AUTOCONF_ROOT=autoconf-2.69
AUTOCONF_HASH=954bd69b391edc12d6a4a51a2dd1476543da5c6bbf05a95b59dc0dd6fd4c2969
AUTOCONF_DOWNLOAD_URL=http://ftp.gnu.org/gnu/autoconf
AUTOMAKE_ROOT=automake-1.16.2
AUTOMAKE_HASH=b2f361094b410b4acbf4efba7337bdb786335ca09eb2518635a09fb7319ca5c1
AUTOMAKE_DOWNLOAD_URL=http://ftp.gnu.org/gnu/automake
LIBTOOL_ROOT=libtool-2.4.6
LIBTOOL_HASH=e3bd4d5d3d025a36c21dd6af7ea818a2afcd4dfc1ea5a17b39d7854bcd0c06e3
LIBTOOL_DOWNLOAD_URL=http://ftp.gnu.org/gnu/libtool

PATCHELF_VERSION=0.10
PATCHELF_HASH=b3cb6bdedcef5607ce34a350cf0b182eb979f8f7bc31eae55a93a70a3f020d13

XZ_ROOT=xz-5.2.5
XZ_HASH=f6f4910fd033078738bd82bfba4f49219d03b17eb0794eb91efbae419f4aba10
XZ_DOWNLOAD_URL=https://tukaani.org/xz

TAR_ROOT=tar-1.32
TAR_HASH=b59549594d91d84ee00c99cf2541a3330fed3a42c440503326dab767f2fbb96c
TAR_DOWNLOAD_URL=https://ftp.gnu.org/gnu/tar

SQLITE_AUTOCONF_VERSION=sqlite-autoconf-3310100
SQLITE_AUTOCONF_HASH=62284efebc05a76f909c580ffa5c008a7d22a1287285d68b7825a2b6b51949ae
SQLITE_AUTOCONF_DOWNLOAD_URL=https://www.sqlite.org/2020

LIBFFI_VERSION=3.3
LIBFFI_ROOT=libffi-$LIBFFI_VERSION
LIBFFI_HASH=72fba7922703ddfa7a028d513ac15a85c8d54c8d67f55fa5a4802885dc652056
LIBFFI_DOWNLOAD_URL=https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION

LIBXCRYPT_VERSION=4.4.16
LIBXCRYPT_HASH=a98f65b8baffa2b5ba68ee53c10c0a328166ef4116bce3baece190c8ce01f375
LIBXCRYPT_DOWNLOAD_URL=https://codeload.github.com/besser82/libxcrypt/tar.gz

OPENSSH_ROOT=openssh-8.2p1
OPENSSH_HASH=43925151e6cf6cee1450190c0e9af4dc36b41c12737619edff8bcebdff64e671
OPENSSH_DOWNLOAD_URL=https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable

GIT_ROOT=2.26.1
GIT_HASH=afb921d44f80953005b4e35c6eb9bc98dd86739f04715080751345475774c194
GIT_DOWNLOAD_URL=https://github.com/git/git/archive

PYTHON_DOWNLOAD_URL=https://www.python.org/ftp/python
# of the form <maj>.<min>.<rev> or <maj>.<min>.<rev>rc<n>
CPYTHON_VERSIONS="2.7.18 3.8.2"

NODE_VERSION=14.0.0
NODE_ROOT=node-v${NODE_VERSION}
NODE_HASH=5ee2a8d3036a1652ec93bbd8b5812e0ae41e0450af729b14df4a27afc6f17cf8
NODE_DOWNLOAD_URL=https://nodejs.org/dist/v${NODE_VERSION}

export \
    CC="$CC -static-libgcc -fuse-ld=gold" \
    CXX="$CXX -static-libgcc -static-libstdc++ -fuse-ld=gold" \
    CFLAGS="-pipe -ffunction-sections -fdata-sections -fPIC" \
    LDFLAGS="-Wl,--icf=all -Wl,--gc-sections -Wl,-z,noexecstack" \
    FORCE_UNSAFE_CONFIGURE=1
