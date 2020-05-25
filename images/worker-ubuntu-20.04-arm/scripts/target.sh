#!/bin/bash

QEMU_AUDIO_DRV=none \
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -nographic \
    -mon chardev=char0,mode=readline \
    -chardev pipe,id=char0,path=/opt/frida/monitor \
    -serial chardev:char1 \
    -chardev pipe,id=char1,path=/opt/frida/serial \
    -smp 1 \
    -m 2048 \
    -no-reboot \
    -kernel /opt/frida/kernel \
    -initrd /opt/frida/initrd \
    -drive file=/opt/frida/rootfs,if=virtio,format=raw \
    -device virtio-net-pci,netdev=mynet \
    -netdev user,id=mynet,net=192.168.76.0/24,hostfwd=tcp::8010-192.168.76.20:8010 \
    -fsdev local,id=creds_dev,path=/opt/frida/creds,security_model=none \
    -device virtio-9p-pci,fsdev=creds_dev,mount_tag=creds \
    -fsdev local,id=build_dev,path=/opt/frida/build,security_model=none \
    -device virtio-9p-pci,fsdev=build_dev,mount_tag=build \
    --append "console=ttyAMA0 panic=-1 root=/dev/vda" &

expect -f /opt/expect-serial.script "$@" < /opt/frida/serial.out > /opt/frida/serial.in
SERIAL_RET=$?
if [ $SERIAL_RET -eq 0 ]; then
  echo -e "\nSuccessfully communicated with serial"
else
  echo -e "\nFailed to communicate with serial"
fi

expect -f /opt/expect-monitor.script < /opt/frida/monitor.out > /opt/frida/monitor.in
if [ $? -eq 0 ]; then
  echo -e "\nSuccessfully communicated with monitor"
else
  echo -e "\nFailed to communicate with monitor"
  exit 1
fi

echo ">>> TARGET: $SERIAL_RET"
exit $SERIAL_RET
