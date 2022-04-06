FROM ubuntu:20.04

LABEL maintainer="oleavr@frida.re"

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		build-essential \
		curl \
		git \
		gperf \
		lib32z1 \
		libc6-i386 \
		locales \
		nodejs \
		npm \
		python3-pip \
		python3-requests \
		python3-setuptools \
		qemu-system-arm \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/* \
	&& pip3 install --no-cache-dir \
		agithub==2.2.2 \
		python-magic==0.4.25 \
		requests==2.27.1 \
		s3cmd==2.2.0 \
	&& npm install -g \
		cloudflare-cli@4.2.0

COPY sdp/opt/qnx650 /opt/qnx650
COPY sdp/etc/qnx /etc/qnx
COPY sabrelite/bsp/install /opt/sabrelite/assets
COPY sabrelite/run.sh /opt/sabrelite

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    QNX_HOST=/opt/qnx650/host/linux/x86 \
    QNX_TARGET=/opt/qnx650/target/qnx6 \
    MAKEFLAGS=-I/opt/qnx650/target/qnx6/usr/include \
    PATH=${PATH}:/opt/qnx650/host/linux/x86/usr/bin:/etc/qnx/bin

ENTRYPOINT ["/bin/bash"]
