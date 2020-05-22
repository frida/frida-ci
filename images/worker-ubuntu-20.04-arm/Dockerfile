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

RUN apt-get install -y gcc-aarch64-linux-gnu

#### Build Busybox ####
WORKDIR /root/
RUN git clone git://busybox.net/busybox.git
WORKDIR /root/busybox/
RUN make defconfig
RUN sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config
RUN CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- make -j8 install

RUN apt-get update
RUN apt-get install -y cpio
RUN apt-get install -y qemu-system-arm

#### Build Kernel ####
WORKDIR /root/
RUN curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.41.tar.xz \
    --output linux-5.4.41.tar.xz
RUN tar Jxvf linux-5.4.41.tar.xz
WORKDIR /root/linux-5.4.41/
RUN ARCH=arm64 make defconfig
RUN sed -i "s/# CONFIG_BINFMT_MISC is not set/CONFIG_BINFMT_MISC=y/g" .config
RUN apt-get install -y bc
RUN ARCH=arm64 CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- make -j8 Image

WORKDIR /root/
RUN cp linux-5.4.41/arch/arm64/boot/Image ./Image

#### Build Ubuntu SquashFs ####
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

# #### Build Initrd  ####
WORKDIR /root/busybox/_install/
RUN mkdir proc/
RUN mkdir sys/
RUN mkdir tmp/
COPY ./src/initrd/ ./
RUN find . | cpio -o -H newc > /root/initrd

RUN mkfifo /tmp/monitor.in /tmp/monitor.out
RUN mkfifo /tmp/serial.in /tmp/serial.out

WORKDIR /root/
RUN mkdir ./creds/
RUN mkdir ./build/
VOLUME ["/root/creds/", "/root/build/"]
RUN apt-get install -y expect
COPY ./scripts/ /opt/
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

RUN apt-get install -y e2tools
COPY ./buildbot.sh /root/buildbot.sh
RUN e2cp -P 755 -O 0 -G 0 /root/buildbot.sh /root/rootfs.ext2:/opt/
RUN /opt/target.sh /opt/buildbot.sh
COPY ./buildbot.tac /root/buildbot.tac
RUN e2cp -P 755 -O 500 -G 500 /root/buildbot.tac /root/rootfs.ext2:/worker/
EXPOSE 8010