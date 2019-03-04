FROM fedora:28
LABEL maintainer="oleavr@frida.re"

RUN dnf install -y \
	gcc-c++ \
	git-core \
	glibc-devel.i686 \
	glibc-devel.x86_64 \
	libstdc++-static.i686 \
	libstdc++-static.x86_64 \
	make \
	python2-colorama \
	python2-devel \
	python2-pip \
	python2-pygments \
	python2-setuptools \
	python3-colorama \
	python3-devel \
	python3-pip \
	python3-pygments \
	python3-requests \
	python3-setuptools \
	rpmdevtools \
	ruby-devel \
	which \
	&& curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
	&& dnf install -y nodejs \
	&& dnf clean all \
	&& pip3 install agithub==2.1 buildbot-worker==1.1.2 prompt-toolkit==1.0.15 \
	&& gem install fpm -v 1.10.0 --no-ri --no-rdoc \
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& chown -R buildbot:buildbot /home/buildbot \
	&& mkdir -p /worker/info /worker/frida-fedora_28-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Fedora 28 x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-fedora_28-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
