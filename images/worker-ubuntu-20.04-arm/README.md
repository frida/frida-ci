# frida-docker

This Docker image is based on Ubuntu 20.04 x86_64. Within this Docker container,
an ARM based target image is constructed consisting of a kernel, initrd and
rootfs. This is later launched within `qemu-system-aarch64` to provide our
target. Note that this target is based on a 64-bit kernel running 32-bit apps.
Ubuntu 20.04 has dropped a 32bit ARM distribution and it is expected that many
other distributions may do also. However, it is not uncommon for legacy apps to
be more complex to port and hence AArch64 architecture has strong support for
running AArch32 apps in user-space.

Henceforth, the ARM based environment used to run the test will be referred to
as the `target`. The Docker environment in which this is all constructed will be
referred to as the `container` and lastly the operating system on which the
`docker` commands are run will be referred to as the `host`.

## Building

To build the image, run `./build.sh`. Note that this may take up to an hour,
even on a modestly equipped workstation.

## QEMU User

```Dockerfile
FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y \
    git \
    make \
    curl \
    build-essential \
    binutils-arm-linux-gnueabi \
    gcc-arm-linux-gnueabi \
    g++-arm-linux-gnueabi \
    xz-utils \
    bison \
    flex \
    gawk \
    python \
    python3 \
    python3-setuptools
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 2
RUN update-alternatives --set python /usr/bin/python2

#### Build Frida SDK ####
WORKDIR /root/
RUN git clone https://github.com/frida/frida.git
WORKDIR /root/frida/
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-arm

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y tzdata
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

#### Build Frida Gum/Core ####
RUN apt-get install -y npm
RUN make gum-linux-arm
RUN make core-linux-arm

#### Install QEMU User ####
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-armel-cross
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-user
ARG QEMU_LD_PREFIX=/usr/arm-linux-gnueabi
RUN qemu-arm ./build/tmp_thin-linux-arm/frida-gum/tests/gum-tests \
        -s /Core/Stalker/performance \
        -s /Core/Stalker/can_follow_workload \
        -s /Core/Stalker/follow_syscall \
        -s /Core/Stalker/follow_thread \
        -s /Core/Stalker/unfollow_should_handle_terminated_thread \
        -s /Core/Stalker/pthread_create \
        -s /Core/Stalker/heap_api \
        -p /Core/Stalker
RUN qemu-arm ./build/tmp_thin-linux-arm/frida-gum/tests/gum-tests \
        -p /Core/ArmWriter
RUN qemu-arm ./build/tmp_thin-linux-arm/frida-gum/tests/gum-tests \
        -p /Core/ArmRelocator
RUN qemu-arm ./build/tmp_thin-linux-arm/frida-gum/tests/gum-tests \
        -p /Core/ThumbWriter
RUN qemu-arm ./build/tmp_thin-linux-arm/frida-gum/tests/gum-tests \
        -p /Core/ThumbRelocator
```

This first section of the Dockerfile installs the necessary tools to cross compile frida for AArch32. It then builds the SDK, Gum and Core. The `gum-tests` are then run on `qemu-arm` which is able to carry out many of the tests, but runs into problems when Frida attempts to `ptrace` itself.

The `gum-tests` binary is later transferred to the target image to confirm the configuration of the target is suitable for running the tests. This stage of the Dockerfile may be removed at a later point once the buildbot in the target compiles frida natively and runs the tests. Perhaps a more representative configuration might be for the current Dockerfile to be split into two buildbot targets, one including the tools to cross compile Frida and the other containing only a target suitable for executing the tests. This configuration should be suitable to allow us to regression test Frida on Linux ARM32 targets. A later improvement may be to provide a much older glibc-2.5 based toolchain (perhaps based on [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng)) and target (perhaps based on CentOS 5) like that used for the [manylinux build for x86_64](https://github.com/frida/frida-ci/blob/master/images/worker-manylinux-x86_64/Dockerfile).

## Busybox
We next build busybox. Note that we build this for AArch64 as we have a 64-bit target (as such we first need to install the cross compiler for AArch64 as to this point, we have only build Frida for AArch32). We have to use the HEAD from github since the latest release has some problems with deprecated functions such as `stime` in the latest `glibc` (2.31). Note that we also configure busybox as just on large monolithic static binary so that we don't have to worry about copying any shared object dependencies to our target.

```Dockerfile
WORKDIR /root/
RUN git clone git://busybox.net/busybox.git
WORKDIR /root/busybox/
RUN make defconfig
RUN sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config
RUN CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- make -j8 install

RUN apt-get update
RUN apt-get install -y cpio
RUN apt-get install -y qemu-system-arm
```

## Kernel
We next build the kernel, we just use the latest kernel. In contrast to AArch32, on AArch64 the kernel has just a single default configuration file rather than multiple for different targets. This is because the kernel is capable of using the Device Tree Blob to understand the target hardware (a binary description of the hardware, used as on embedded architectures the ability to probe and detect hardware is often not supported) rather than having to be customized. Note we also add `CONFIG_BINFMT_MISC` to our configuration as we will be using this support later to run AArch32 binaries on our AArch64 kernel.
```Dockerfile
WORKDIR /root/
RUN curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.41.tar.xz \
    --output linux-5.4.41.tar.xz
RUN tar Jxvf linux-5.4.41.tar.xz
WORKDIR /root/linux-5.4.41/
RUN ARCH=arm64 make defconfig
RUN sed -i "s/# CONFIG_BINFMT_MISC is not set/CONFIG_BINFMT_MISC=y/g" .config
RUN apt-get install -y bc
RUN ARCH=arm64 CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- make -j8 Image
```
## RootFS
We next build our rootfs. As a basis for our target, we select the official Ubuntu AArch64 file-system image intended for use in ARM container based cloud deployments. This is provided as a tarball, but we use `genext2fs` to build an ext2 image. We chose this as our root file-system as we want something writeable and persistent and ext2 being older is better supported with tooling. Note that we cannot simply create a flat image file an mount it using a loopback device since the Docker security model prevents the use of loopback devices. In any case, this would add a dependency on the host kernel (since Docker runs in a [namespace](https://lwn.net/Articles/531114/) in the host kernel). 
```Dockerfile
WORKDIR /root/
RUN curl https://partner-images.canonical.com/core/focal/current/ubuntu-focal-core-cloudimg-arm64-root.tar.gz \
    --output ubuntu-focal-core-cloudimg-arm64-root.tar.gz
RUN mkdir rootfs
WORKDIR /root/rootfs/
RUN tar zxvf /root/ubuntu-focal-core-cloudimg-arm64-root.tar.gz

# #### Build Rootfs  ####
WORKDIR /root/
RUN apt-get install -y genext2fs
RUN cp /root/frida/build/tmp_thin-linux-arm/frida-gum/tests/gum-tests \
    /root/rootfs/opt
RUN cp /root/busybox/_install/sbin/halt /root/rootfs/sbin/
COPY ./src/rootfs/ /root/rootfs/

RUN genext2fs -U -N 131072 -B 4096 -b 524288  -d /root/rootfs /root/rootfs.ext2
```
Note that we copy the `halt` binary from busybox into this image. Since this image is intended to run in a Docker based environment using namespaces in the host kernel, it is never actually intended to support shutting down the operating system. We wish to use it when running in QEMU with our own kernel as a fully fledged bootable OS and as such we need to add support to shut it down.

Toward the end of the building of this image, we can see we copy a folder of files into the rootfs from the [repository](https://github.com/WorksButNotTested/frida-ci/blob/feature/worker-arm/images/worker-ubuntu-20.04-arm/src/rootfs/).

In particular, we have the following `/init` script:
```bash
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp
mount -t devtmpfs none /dev
mkdir /dev/pts/
mount -t devpts none /dev/pts/
if test -f "/etc/init.d/binfmt-support"; then
    echo "Starting BINFMT"
    /etc/init.d/binfmt-support start
fi
mkdir -m 777 /tmp/creds/
mount -t 9p -o trans=virtio creds /tmp/creds/ -oversion=9p2000.L,posixacl,cache=loose

mkdir -m 777 /tmp/build/
mount -t 9p -o trans=virtio build /tmp/build/ -oversion=9p2000.L,posixacl,cache=loose

setsid sh -c 'exec bash </dev/ttyAMA0 >/dev/ttyAMA0 2>&1'
```

This mounts the usual pseudo file-systems exposed by the kernel. It then starts the binfmt-support service if it is present. This is installed later in the target configuration process and so it may not exist initially when the target is started to carry out configuration. Next, we see two file-systems being mounted. These use plan9fs support in QEMU using the virtio transport to allow us to mount folder from the container into the target. Lastly, we see some [voodoo ](http://lists.busybox.net/pipermail/busybox/2010-July/072895.html) to allow us to access a controlling [TTY](https://www.linusakesson.net/programming/tty/) for a bash session.

The other files copied to the rootfs configure the binfmt mechanism to support AArch32. The file `/opt/run-arm.sh` is used to launch an AArch32 binary using the loader.
```bash
#!/bin/bash
LD_LIBRARY_PATH=/usr/arm-linux-gnueabi/lib /usr/arm-linux-gnueabi/lib/ld-2.31.so $@
```

The file `/var/lib/binfmts/arm` is used to configure the binfmt mechanism to parse and identify an AArch32 elf and identify it and run the launcher.
```
arm
magic
0
\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00

/opt/run-arm.sh
```
Lastly, `/etc/resolv.conf` is provided to configure the target to use google for DNS resolution.

## Initrd
The last component of our target is the initrd. Note that the initrd is a RAM disk. Any changes to it will be lost after a reboot. We therefore need our rootfs to be distinct from the initrd as we wish to mount that writeable such that changes can persist after the target is reset.

```Dockerfile
WORKDIR /root/busybox/_install/
RUN mkdir proc/
RUN mkdir sys/
RUN mkdir tmp/
COPY ./src/initrd/ ./
RUN find . | cpio -o -H newc > /root/initrd
```

Our initrd is based on the install dir created when we built busybox above. We create a few directories to be used as mount points for the kernel's usual pseudo file-systems and again copy in a folder of files from the [repository](https://github.com/WorksButNotTested/frida-ci/tree/feature/worker-arm/images/worker-ubuntu-20.04-arm/src/initrd). We add the same `/etc/resolv.conf` as the rootfs, and the following `/init` script:

```bash
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp
mount -t devtmpfs none /dev
ip addr add 192.168.76.20/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.76.2 dev eth0
mkdir /tmp/rootfs
mount -t ext2 /dev/vda /tmp/rootfs
exec switch_root /tmp/rootfs/ /init
```
We can see that this configures the network adapter of the target to connect to the container, and then simply mounts and switches to the rootfs running it's `/init` script.

## Volumes
We can see next we create some directories in the container and expose them to the host using the `VOLUME` directive. These folders are in turn exposed to the target so that they can be mounted in its environment using QEMU plan9fs support over virtio. This allows the target environment to write directly to the volumes. 
```Dockerfile
RUN mkdir ./creds/
RUN mkdir ./build/
VOLUME ["/root/creds/", "/root/build/"]
```

## Command & Control
```Dockerfile
RUN mkfifo /tmp/monitor.in /tmp/monitor.out
RUN mkfifo /tmp/serial.in /tmp/serial.out

...

RUN apt-get install -y expect
COPY ./scripts/ /opt/
```
We now have all of the artifacts required for our target environment, but we now need a way to start it. We can see that we create two FIFOs to control the target, one will be connected to the serial port (on which the target will expose its terminal interface) the other will be connected to the QEMU monitor interface. Our target hardware doesn't seem to correctly support power management and hence when we shutdown the target, it will synchronise it's file-systems and shutdown the kernel, but has no working emulated power control hardware. As such, it cannot tell QEMU that the operating system has shutdown and instead the target will simply print a message saying it has shutdown and will then sleep in a loop doing nothing. This will be familiar to early adopters of Linux who often had to press the physical power button on their PC to turn it off. QEMU will not know the guest has shutdown and hence the process will continue to run. However, we can use the monitor interface to quit the guest. We can simply wait for the kernel to print `reboot: System halted` and then instruct QEMU to quit by issuing the `q` command to the monitor.

We can see that the command and control of the target is supported by a number of [scripts](https://github.com/WorksButNotTested/frida-ci/tree/feature/worker-arm/images/worker-ubuntu-20.04-arm/scripts). 

### Test.sh
First, let's look at the `/opt/test.sh` script. This is not used for building the image, but is provided so that a developer can start and interact with the target from the terminal inside the Docker image.

```bash
QEMU_AUDIO_DRV=none \
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -nographic \
    -smp 1 \
    -m 2048 \
    -no-reboot \
    -kernel /root/Image \
    -initrd /root/initrd \
    -drive file=/root/rootfs.ext2,if=virtio,format=raw \
    -device virtio-net-pci,netdev=mynet \
    -netdev user,id=mynet,net=192.168.76.0/24,hostfwd=tcp::8010-192.168.76.20:8010 \
    -fsdev local,id=creds_dev,path=/root/creds,security_model=none \
    -device virtio-9p-pci,fsdev=creds_dev,mount_tag=creds \
    -fsdev local,id=build_dev,path=/root/build,security_model=none \
    -device virtio-9p-pci,fsdev=build_dev,mount_tag=build \
    --append "console=ttyAMA0 panic=-1 root=/dev/vda"
```
We can see our target is based on the virt platform (rather than emulating a test board or production device, this is intended to be used purely for virtual environments to provide simplicity and performance). We have a single emulated Coretex A57 CPU and 2GB of RAM. We configure QEMU not to allow reboot (`--no-reboot`) just in case, although as already discussed we don't have power management support. We specify our kernel, initrd and rootfs (which we mount using a virtio PCI based storage controller). Virtio is an emulated bus designed specifically for high performance in paravirtualized systems, rather than replicating a real-world hardware interface. We next configure a virtio NIC using [SLIRP](https://wiki.qemu.org/Documentation/Networking), although performance of SLIRP is poor, it should be sufficient for our needs and avoids the complexities of attempting to configure TUN and TAP devices in Docker (which like loopback devices is frustrated by Docker's security model, as again we would need support from the host kernel). We next configure two virtio plan9fs storage volumes (the same locations exposed by the `VOLUME` directives in the Dockerfile). Lastly, we configure the kernel command line parameters to attach a console to the serial port (`ttyAMA0`), set the root device and reboot immediately on a kernel panic.

### Target.sh
Next, we look at our `/opt/target.sh`. This script can be passed a series of parameters which are passed to the target environment as a command to be executed. We start the QEMU target in the same way as `/opt/test.sh`, but re-direct the serial and monitor devices to FIFOs. We then use expect scripts to first communicate with the serial port and then with the monitor. Each is started with their `stdin` and `stdout` attached to the corresponding FIFO.
```bash
#!/bin/bash
QEMU_AUDIO_DRV=none \
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -nographic \
    -mon chardev=char0,mode=readline \
    -chardev pipe,id=char0,path=/tmp/monitor \
    -serial chardev:char1 \
    -chardev pipe,id=char1,path=/tmp/serial \
    -smp 1 \
    -m 2048 \
    -no-reboot \
    -kernel /root/Image \
    -initrd /root/initrd \
    -drive file=/root/rootfs.ext2,if=virtio,format=raw \
    -device virtio-net-pci,netdev=mynet \
    -netdev user,id=mynet,net=192.168.76.0/24,hostfwd=tcp::8010-192.168.76.20:8010 \
    -fsdev local,id=creds_dev,path=/root/creds,security_model=none \
    -device virtio-9p-pci,fsdev=creds_dev,mount_tag=creds \
    -fsdev local,id=build_dev,path=/root/build,security_model=none \
    -device virtio-9p-pci,fsdev=build_dev,mount_tag=build \
    --append "console=ttyAMA0 panic=-1 root=/dev/vda" &

expect -f /opt/expect-serial.script "$@" < /tmp/serial.out > /tmp/serial.in
SERIAL_RET=$?
if [ $SERIAL_RET -eq 0 ]
then
  echo -e "\nSuccessfully communicated with serial"
else
  echo -e "\nFailed to communicate with serial"
fi

expect -f /opt/expect-monitor.script < /tmp/monitor.out > /tmp/monitor.in
if [ $? -eq 0 ]
then
  echo -e "\nSuccessfully communicated with monitor"
else
  echo -e "\nFailed to communicate with monitor"
  exit 1
fi

echo ">>> TARGET: $SERIAL_RET"
exit $SERIAL_RET
```

### Serial
Our script for communicating with the serial port is relatively simple. We disable timeouts, and configure our logging to use `stderr` (recall our `stdin` and `stdout` are attached to the FIFO connected to the target's serial port). The rest of the script is fairly self explanatory. We send a newline to cause the target to send back the prompt, we send the command passed to us in `argv` then again wait for the prompt. We then use the command `echo RESULT $?` to reveal the exit code of the previous command to us and error if non-zero. Lastly, we again wait for the prompt and issue a `halt -f` and await the guest to respond with `reboot: System halted`.
```
proc runCommand { command } {
    expect "# "
    send -- "$command \n"
}

proc checkResult { } {
    runCommand "echo RESULT $?"

    expect {
        timeout { error "Timeout" }
        -re {.*RESULT (\d+).*} { set resultCode $expect_out(1,string)}
    }

    if { $resultCode != 0 } {
        error "Command Failed"
    }
}

set timeout -1
log_user 1
log_file -noappend /proc/self/fd/2
send -- "\n"

runCommand "$argv"
checkResult

runCommand "halt -f"
expect "reboot: System halted"

log_file
exit
```
### Monitor
Our monitor script is simpler still. We awit the `(qemu)` prompt and issue the `q` command.

```
log_user 1
log_file -noappend /proc/self/fd/2

expect "(qemu)"
send -- "q \n"

log_file
exit
```
## Target Configuration
We then issue a series of commands to the target using `/opt/target.sh` to perform various configuration steps.
```
RUN /opt/target.sh apt-get update
RUN /opt/target.sh DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN /opt/target.sh ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN /opt/target.sh dpkg-reconfigure --frontend noninteractive tzdata
RUN /opt/target.sh apt-get install -y \
    binfmt-support \
    libc6-armel-cross \
    ncat \
	build-essential \
	curl \
	git \
	libstdc++6 \
	locales \
	nodejs \
	npm \
	python3-dev \
	python3-pip \
	python3-requests \
	python3-setuptools \
	ruby \
    ruby-dev
RUN /opt/target.sh apt-get install -y gcc-arm-linux-gnueabi g++-arm-linux-gnueabi
RUN /opt/target.sh PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        pip3 install \
		agithub==2.2.2 \
		buildbot-worker==2.7.0
RUN /opt/target.sh PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        gem install fpm -v 1.11.0 --no-document
```

Lastly, we use a `COPY` directive to copy the `buildbot.tac` to the Docker container and `e2tools` to subsequently copy the file into the target ext2 file-system. Note that we carefully control the permissions and UID/GID of the files we copy (the `buildbot` user is configured with UID/GID 500).
```
RUN apt-get install -y e2tools
COPY ./buildbot.sh /root/buildbot.sh
RUN e2cp -P 755 -O 0 -G 0 /root/buildbot.sh /root/rootfs.ext2:/opt/
RUN /opt/target.sh /opt/buildbot.sh
COPY ./buildbot.tac /root/buildbot.tac
RUN e2cp -P 755 -O 500 -G 500 /root/buildbot.tac /root/rootfs.ext2:/worker/
```

We also use the same mechanism to copy the [buildbot.sh](https://github.com/WorksButNotTested/frida-ci/blob/feature/worker-arm/images/worker-ubuntu-20.04-arm/buildbot.sh) file into the target and then subseuently use `/opt/target.sh` to call it to perform some configuration. This avoids the overhead of starting and stopping the target to perform very simple short commands and the unnecessary overhead of storing so many Docker images during the build process.

```bash
#!/bin/bash
set -x
groupadd -r buildbot -g 500
useradd -r -g buildbot buildbot -u 500

mkdir /home/buildbot/
chown buildbot:buildbot /tmp/creds
ln -s /tmp/creds/ /home/buildbot/.credentials
ln -s .credentials/github-token /home/buildbot/.frida-release-github-token
ln -s .credentials/npmrc /home/buildbot/.npmrc
ln -s .credentials/pypirc /home/buildbot/.pypirc

chown -R buildbot:buildbot /home/buildbot
mkdir -p /worker/info /worker/frida-ubuntu_20_04-arm/

chown buildbot:buildbot /tmp/build
ln -s /tmp/build/ /worker/frida-ubuntu_20_04-arm/build

echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin
echo 'Ubuntu 20.04 arm' > /worker/info/host
chown -R buildbot:buildbot /worker
```
The `buildbot.sh` script creates the `buildbot` user (note again the hardcoded UID/GID) as well as creating necessary folders and creating symlinks to map the necessary locations for the `buildbot-worker` to the mounted plan9 file-systems from the container which are then in turn exposed to the host.

## Networking
Lastly, we expose port 8010 for the container, recall that QEMU was configured to port forward this directly to the target and hence the port maps directly to the `buildbot` worker in the target.
```
EXPOSE 8010
```
