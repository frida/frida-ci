FROM ubuntu:21.04

LABEL maintainer="oleavr@frida.re"

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	build-essential \
	curl \
	git \
	lib32stdc++-10-dev \
	libc6-dev-i386 \
	locales \
	nodejs \
	npm \
	python3-dev \
	python3-pip \
	python3-requests \
	python3-setuptools \
	ruby \
	ruby-dev \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/* \
	&& pip3 install --no-cache-dir \
		agithub==2.2.2 \
		buildbot-worker==3.1.1 \
	&& gem install fpm -v 1.12.0 --no-document \
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& chown -R buildbot:buildbot /home/buildbot \
	&& mkdir -p /worker/info /worker/frida-ubuntu_21_04-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Ubuntu 21.04 x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-ubuntu_21_04-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
