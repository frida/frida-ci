FROM fedora:34

LABEL maintainer="oleavr@frida.re"

RUN dnf install -y \
	gcc-c++ \
	git-core \
	glibc-devel.i686 \
	glibc-devel.x86_64 \
	libatomic.i686 \
	libatomic.x86_64 \
	libstdc++-static.i686 \
	libstdc++-static.x86_64 \
	make \
	nodejs \
	python3-devel \
	python3-pip \
	python3-requests \
	python3-setuptools \
	rpmdevtools \
	ruby-devel \
	which \
	&& dnf clean all \
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
	&& mkdir -p /worker/info /worker/frida-fedora_34-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Fedora 34 x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-fedora_34-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
