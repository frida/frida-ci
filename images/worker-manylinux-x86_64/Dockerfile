FROM fridadotre/manylinux-x86_64

LABEL maintainer="oleavr@frida.re"

ENV PATH="/opt/python-64/cp27-cp27mu/bin:/opt/python-64/cp38-cp38/bin:/opt/node-64/bin:$PATH"

RUN \
	yum -y install \
		bison \
		flex \
	&& yum -y clean all \
	&& pip3 install \
		agithub==2.2.2 \
		buildbot-worker==2.7.0 \
		requests==2.23.0 \
	\
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& chown -R buildbot:buildbot /home/buildbot \
	&& mkdir -p /worker/info /worker/frida-manylinux-x86_64/build \
	&& echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin \
	&& echo 'ManyLinux x86_64' > /worker/info/host \
	&& chown -R buildbot:buildbot /worker
COPY --chown=buildbot:buildbot buildbot.tac /worker/buildbot.tac

USER buildbot
WORKDIR /worker
VOLUME ["/home/buildbot/.credentials", "/worker/frida-manylinux-x86_64/build"]

ENTRYPOINT ["buildbot-worker"]
CMD ["start", "--nodaemon"]
