FROM arm64v8/ubuntu:18.04

LABEL maintainer="oleavr@frida.re"

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		build-essential \
		curl \
		git \
		locales \
		python-setuptools \
		python2.7-dev \
		python3-dev \
		python3-setuptools \
		software-properties-common \
	&& add-apt-repository ppa:deadsnakes/ppa \
	&& curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		nodejs \
		python3.8-dev \
		python3.8-full \
	&& curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
	&& python3.8 get-pip.py \
	&& rm get-pip.py \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/* \
	&& pip3 install --no-cache-dir \
		agithub==2.2.2 \
		buildbot-worker==3.1.1 \
		requests==2.25.1 \
	\
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& chown -R buildbot:buildbot /home/buildbot \
	&& mkdir -p /worker/info /worker/frida-ubuntu_18_04-arm64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Ubuntu 18.04 arm64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-ubuntu_18_04-arm64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
