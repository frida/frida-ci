FROM fridadotre/manylinux-base-x86_64

LABEL description="Environment for building portable Linux binaries using modern GCC"
LABEL maintainer="oleavr@frida.re"

ARG CORES=8
ARG DEVTOOLS_PREFIX=/opt/devtools

ENV AUDITWHEEL_PLAT manylinux1_x86_64

COPY build_scripts /build_scripts
COPY sources /
RUN bash /build_scripts/build.sh && rm -r /build_scripts

ENV SSL_CERT_FILE=/opt/_internal/certs.pem

CMD ["/bin/bash"]
