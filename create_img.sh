IMAGE=windows-server-2012-r2-1.qcow2
FLOPPY=Autounattend.vfd
VIRTIO_ISO=virtio-win-0.1-94.iso
ISO=9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO

echo "creating FLOPPY"

KVM=/usr/libexec/qemu-kvm
if [ ! -f "$KVM" ]; then
    KVM=/usr/bin/kvm
fi
echo "creating disk!"
qemu-img create -f qcow2 -o preallocation=metadata $IMAGE 17G
echo "installing windows on disk!"
$KVM -m 2048 -smp 2 -cdrom $ISO -drive file=$VIRTIO_ISO,index=3,media=cdrom,boot=on -fda $FLOPPY $IMAGE -boot d -vga std -k en-us -vnc :3

