qemu-img create -f raw VM60G.raw 60G
qemu-system-x86_64 -smp 16 -m 32768 -hda VM60G.raw -cdrom FreeBSD-13.0-RELEASE-amd64-disc1.iso

