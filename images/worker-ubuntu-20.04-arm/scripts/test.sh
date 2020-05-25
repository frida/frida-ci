#!/bin/sh

QEMU_AUDIO_DRV=none \
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -nographic \
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
    --append "console=ttyAMA0 panic=-1 root=/dev/vda"
