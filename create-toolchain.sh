#! /bin/bash -e

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
# build/frida-linux-x86_64/share/aclocal/??
mkdir -p build/toolchain/bin/

ln -sf $HOME/apps/valac/bin/valac-0.14 build/toolchain/bin/valac-0.14

export FRIDA_TARGET=linux-x86_64
./setup-env.sh

(
  . build/frida-env-linux-x86_64.rc
  ./build-deps.sh toolchain
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
  ./build-deps.sh sdk
)

echo "For upload:"
echo build/toolchain*.tar.bz2
echo build/sdk-linux*.tar.bz2
