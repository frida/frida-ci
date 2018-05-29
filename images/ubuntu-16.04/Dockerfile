FROM ubuntu:16.04
LABEL maintainer="oleavr@frida.re"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	build-essential \
	curl \
	gcc-multilib \
	git \
	lib32stdc++-5-dev \
	locales \
	python-colorama \
	python-dev \
	python-prompt-toolkit \
	python-pygments \
	python-setuptools \
	ruby \
	ruby-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
	&& apt-get install -y nodejs
RUN gem install fpm -v 1.9.3 --no-ri --no-rdoc

VOLUME [ "/src" ]
WORKDIR /src

ENTRYPOINT [ "/bin/bash" ]
CMD []
