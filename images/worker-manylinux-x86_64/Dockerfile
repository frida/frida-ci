FROM fridadotre/manylinux-x86_64

LABEL maintainer="oleavr@frida.re"

ENV PATH="/opt/python-64/cp27-cp27mu/bin:/opt/python-64/cp38-cp38/bin:/opt/node-64/bin:$PATH"

RUN \
	yum -y install \
		bison \
		flex \
	&& yum -y clean all \
	&& pip3 install --no-cache-dir \
		agithub==2.2.2 \
		buildbot-worker==3.1.1 \
		requests==2.25.1 \
		s3cmd==2.1.0 \
	&& npm install -g \
		cloudflare-cli@4.2.0 \
	\
	&& groupadd -r buildbot \
	&& useradd -r -g buildbot buildbot \
	&& mkdir -p /home/buildbot/.credentials \
	&& ln -s .credentials/cfcli.yml /home/buildbot/.cfcli.yml \
	&& ln -s .credentials/github-token /home/buildbot/.frida-release-github-token \
	&& ln -s .credentials/npmrc /home/buildbot/.npmrc \
	&& ln -s .credentials/pypirc /home/buildbot/.pypirc \
	&& ln -s .credentials/s3cfg /home/buildbot/.s3cfg \
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
