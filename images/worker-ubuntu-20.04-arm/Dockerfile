FROM ubuntu:20.04

ARG CORES=8

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	binutils-arm-linux-gnueabi \
	bison \
	build-essential \
	curl \
	expect \
	flex \
	g++-arm-linux-gnueabi \
	gawk \
	gcc-arm-linux-gnueabi \
	git \
	libc6-armel-cross \
	make \
	npm \
	python \
	python3 \
	python3-setuptools \
	qemu-system-arm \
	qemu-user \
	tzdata \
	xz-utils \
	&& ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime \
	&& dpkg-reconfigure --frontend noninteractive tzdata \
	&& update-alternatives --install /usr/bin/python python /usr/bin/python2 1 \
	&& update-alternatives --install /usr/bin/python python /usr/bin/python3 2 \
	&& update-alternatives --set python /usr/bin/python2 \
	&& apt-get clean

#### Build Frida SDK ####
RUN cd /usr/local/src/ \
	&& mkdir /opt/frida/ \
	&& git clone https://github.com/frida/frida.git \
	&& pushd frida \
		&& make -f Makefile.sdk.mk FRIDA_HOST=linux-arm \
		&& mv build/sdk-linux-arm.tar.gz /opt/frida/ \
	&& popd \
	&& rm -rf frida

#### Build Target System ####
COPY ./src/rootfs/ /usr/local/src/rootfs/
COPY ./src/initrd/ /usr/local/src/initrd/
RUN cd /usr/local/src/ \
	&& target_build_deps="bc cpio gcc-aarch64-linux-gnu genext2fs" \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y $target_build_deps \
	\
	&& git clone git://busybox.net/busybox.git \
	&& pushd busybox \
		&& make defconfig \
		&& sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config \
		&& CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- make -j$CORES install \
	&& popd \
	\
	&& mkdir linux \
	&& pushd linux \
		&& curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.6.14.tar.xz \
			| tar -xJf - --strip-components=1 \
		&& ARCH=arm64 make defconfig \
		&& sed -i "s/# CONFIG_BINFMT_MISC is not set/CONFIG_BINFMT_MISC=y/g" .config \
		&& ARCH=arm64 CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- make -j$CORES Image \
		&& mv arch/arm64/boot/Image /opt/frida/kernel \
	&& popd \
	\
	&& curl https://partner-images.canonical.com/core/focal/current/ubuntu-focal-core-cloudimg-arm64-root.tar.gz \
		| tar -xzf - -C rootfs --skip-old-files \
	&& cp busybox/_install/sbin/halt rootfs/sbin/ \
	&& genext2fs -U -N 131072 -B 4096 -b 524288 -d rootfs /opt/frida/rootfs \
	\
	&& tar -C initrd -cf - . | tar -C busybox/_install -xf - \
	&& pushd busybox/_install \
		&& mkdir -p proc sys tmp \
		&& find . | cpio -o -H newc > /opt/frida/initrd \
	&& popd \
	\
	&& mkfifo /opt/frida/monitor.in /opt/frida/monitor.out \
	&& mkfifo /opt/frida/serial.in /opt/frida/serial.out \
	\
	&& rm -rf busybox linux rootfs \
	&& dpkg -P $target_build_deps \
	&& apt-get autoremove -y \
	&& apt-get clean

WORKDIR /root/
RUN mkdir ./credentials/
RUN mkdir ./build/
VOLUME ["/root/credentials/", "/root/build/"]
COPY ./scripts/ /opt/
RUN /opt/target.sh apt-get update
RUN /opt/target.sh DEBIAN_FRONTEND=noninteractive apt-get install -y \
	binfmt-support \
	build-essential \
	curl \
	g++-arm-linux-gnueabi \
	gcc-arm-linux-gnueabi \
	git \
	libc6-armel-cross \
	libstdc++6 \
	locales \
	ncat \
	nodejs \
	npm \
	python3-dev \
	python3-pip \
	python3-requests \
	python3-setuptools \
	ruby \
	ruby-dev \
	tzdata
RUN /opt/target.sh ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
RUN /opt/target.sh dpkg-reconfigure --frontend noninteractive tzdata
RUN /opt/target.sh PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
	pip3 install \
		agithub==2.2.2 \
		buildbot-worker==2.7.0
RUN /opt/target.sh PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
	gem install fpm -v 1.11.0 --no-document

RUN apt-get install -y e2tools
COPY ./buildbot.sh /root/buildbot.sh
RUN e2cp -P 755 -O 0 -G 0 /root/buildbot.sh /opt/frida/rootfs:/opt/
RUN /opt/target.sh /opt/buildbot.sh
COPY ./buildbot.tac /root/buildbot.tac
RUN e2cp -P 755 -O 500 -G 500 /root/buildbot.tac /opt/frida/rootfs:/worker/
EXPOSE 8010
