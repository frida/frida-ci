#! /bin/bash -e

bp=$(cd $(dirname $0) ; pwd)

if [ ! -f $bp/build-deps.sh ] ; then
  echo "Missing required script $0/build-deps.sh" > /dev/stderr
  exit 1
fi

rm -rf $HOME/apps/valac
rm -rf frida-build-env
rm -rf valac

pushd .
mkdir -p valac
cd valac
wget http://download.gnome.org/sources/vala/0.14/vala-0.14.2.tar.xz
tar Jxvf vala-0.14.2.tar.xz
cd vala-0.14.2
./configure --prefix=$HOME/apps/valac
make all install
popd

git clone git://github.com/frida/frida-build-env.git
cd frida-build-env
git submodule init
git submodule update

mkdir -p build/toolchain/share/aclocal/
mkdir -p build/sdk-linux-x86_64/share/aclocal/
mkdir -p build/toolchain/bin/

ln -sf $HOME/apps/valac/bin/valac-0.14 build/toolchain/bin/valac-0.14

export FRIDA_TARGET=linux-x86_64
./setup-env.sh

(
  . build/frida-env-linux-x86_64.rc
  FRIDA_ROOT=`pwd` $bp/build-deps.sh toolchain
)

pushd .
cd build
rm -rf toolchain
tar jxvf toolchain-linux-*.tar.bz2
rm -rf frida-linux-x86_64
rm -rf tmp-linux-x86_64
popd

./setup-env.sh
(
  . build/frida-env-linux-x86_64.rc
  FRIDA_ROOT=`pwd` $bp/build-deps.sh sdk
)

echo "New toolchain and SDK ready for upload:"
echo build/toolchain*.tar.bz2
echo build/sdk-linux*.tar.bz2
