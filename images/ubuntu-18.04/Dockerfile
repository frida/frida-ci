FROM ubuntu:18.04
LABEL maintainer="oleavr@frida.re"

RUN apt-get update \
	&& apt-get install -y \
	build-essential \
	curl \
	git \
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
	&& pip3 install agithub buildbot-worker \
	&& gem install fpm -v 1.10.0 --no-ri --no-rdoc \
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& chown -R buildbot:buildbot /home/buildbot \
	&& mkdir -p /worker/info /worker/frida-ubuntu_18_04-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Ubuntu 18.04 x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-ubuntu_18_04-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
