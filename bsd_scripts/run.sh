GRAPHIC="-nographic"
# GRAPHIC=""
# DEBUG="-s -S"
DEBUG=""
screen -d -m qemu-system-x86_64 ${DEBUG} -smp 16 -m 32768 -hda VM60G.raw ${GRAPHIC} -net user,hostfwd=tcp::5000-:22 -net nic
