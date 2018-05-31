FROM ubuntu:16.04
LABEL maintainer="oleavr@frida.re"

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	build-essential \
	curl \
	gcc-multilib \
	git \
	lib32stdc++-5-dev \
	locales \
	python-colorama \
	python-dev \
	python-pip \
	python-prompt-toolkit \
	python-pygments \
	python-setuptools \
	python3-colorama \
	python3-dev \
	python3-pip \
	python3-prompt-toolkit \
	python3-pygments \
	python3-requests \
	python3-setuptools \
	ruby \
	ruby-dev \
	&& curl -sL https://deb.nodesource.com/setup_10.x | bash - \
	&& apt-get install -y nodejs \
	&& rm -rf /var/lib/apt/lists/* \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=en_US.UTF-8 \
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& chown -R buildbot:buildbot /home/buildbot \
	&& mkdir -p /worker/info /worker/frida-ubuntu_16_04-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Ubuntu 16.04 x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN pip3 install agithub buildbot-worker \
	&& gem install fpm -v 1.9.3 --no-ri --no-rdoc

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-ubuntu_16_04-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
