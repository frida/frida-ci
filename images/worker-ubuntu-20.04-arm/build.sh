#!/bin/bash
date
time docker build --rm --tag frida-docker .
date
docker run --rm -it --name frida-docker -p:8010:8010 frida-docker /bin/bash