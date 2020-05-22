#!/bin/bash
set -x
groupadd -r buildbot -g 500
useradd -r -g buildbot buildbot -u 500

mkdir /home/buildbot/
chown buildbot:buildbot /tmp/creds
ln -s /tmp/creds/ /home/buildbot/.credentials
ln -s .credentials/github-token /home/buildbot/.frida-release-github-token
ln -s .credentials/npmrc /home/buildbot/.npmrc
ln -s .credentials/pypirc /home/buildbot/.pypirc

chown -R buildbot:buildbot /home/buildbot
mkdir -p /worker/info /worker/frida-ubuntu_20_04-arm/

chown buildbot:buildbot /tmp/build
ln -s /tmp/build/ /worker/frida-ubuntu_20_04-arm/build

echo 'Ole Andre Vadla Ravnas <oleavr@frida.re>' > /worker/info/admin
echo 'Ubuntu 20.04 arm' > /worker/info/host
chown -R buildbot:buildbot /worker
