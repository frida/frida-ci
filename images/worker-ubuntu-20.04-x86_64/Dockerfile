FROM ubuntu:20.04

LABEL maintainer="oleavr@frida.re"

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	build-essential \
	curl \
	git \
	lib32stdc++-9-dev \
	libc6-dev-i386 \
	libgl1-mesa-dev \
	locales \
	nodejs \
	npm \
	p7zip \
	python3-dev \
	python3-pip \
	python3-requests \
	python3-setuptools \
	ruby \
	ruby-dev \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=en_US.UTF-8 \
	&& mkdir /opt/qt \
	&& cd /opt/qt \
	&& curl -L -o qtbase.7z https://download.qt.io/online/qtsdkrepository/linux_x64/desktop/qt5_5152/qt.qt5.5152.gcc_64/5.15.2-0-202011130601qtbase-Linux-RHEL_7_6-GCC-Linux-RHEL_7_6-X86_64.7z \
	&& curl -L -o qtdeclarative.7z https://download.qt.io/online/qtsdkrepository/linux_x64/desktop/qt5_5152/qt.qt5.5152.gcc_64/5.15.2-0-202011130601qtdeclarative-Linux-RHEL_7_6-GCC-Linux-RHEL_7_6-X86_64.7z \
	&& curl -L -o icu.7z https://download.qt.io/online/qtsdkrepository/linux_x64/desktop/qt5_5152/qt.qt5.5152.gcc_64/5.15.2-0-202011130601icu-linux-Rhel7.2-x64.7z \
	&& (for pkg in qtbase qtdeclarative icu; do \
		7zr x $pkg.7z || exit $?; \
	done) \
	&& rm *.7z \
	&& mv 5.15.2/gcc_64/* . \
	&& rm -r 5.15.2 \
	&& sed -i -e "s,QT_EDITION = Enterprise,QT_EDITION = OpenSource," -e "/QT_LICHECK = /d" mkspecs/qconfig.pri \
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
	&& mkdir -p /worker/info /worker/frida-ubuntu_20_04-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'Ubuntu 20.04 x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-ubuntu_20_04-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
