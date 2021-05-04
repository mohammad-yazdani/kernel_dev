# The Hitchhiker's Guide to messing around with kernel-space
This repository is has some usefull scripts and info on people who want to make changes to existing kernel and NOT if you want to make your own kernel.
The patches are related to my research on epoll/kevent.
## Development setup
### Linux (tiny kenel)
#### With tmux
- Simply run `debug.sh` :)
- I recommend reading the `debug.sh` script before using it, it's pretty short.

#### With Visual Studio Code
1. Run `debug.sh --only-build` first so that you have access to kernel code.
2. Make a `.vscode` directory in the newly cloned `linux`:
```mkdir -p linux/.vscode```
3. Copy the two JSON files in `vscode` to `linux/.vscode`.
4. Open the `linux` folder in VSCode (not the `kernel_dev` project root).
5. You should have a debug option called `Debug kernel`, which debugs the kernel.

### Debian
- This guide assumes you are developing on Ubuntu 20.04 LTS Focal
- For Debian and Debian based builds (Ubuntu), please first have a look at the following pages:
    - https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel
    - https://linuxconfig.org/custom-kernels-in-ubuntu-debian-how-when-and-why

Run the following as root:
```bash
echo "deb-src http://archive.ubuntu.com/ubuntu focal main" >> /etc/apt/sources.list
echo "deb-src http://archive.ubuntu.com/ubuntu focal-updates main" >> /etc/apt/sources.list
apt update
apt-get build-dep -y linux linux-image-$(uname -r)
apt install -y sudo apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf
```
Run the following as user:
```bash
apt source linux-source-5.4.0
cd linux-source-5.4.0
make oldconfig # This is to copy your current config from /boot
# make menuconfig # To make additional changes
##########################
# Make your code changes #
##########################
make -j $(nproc) # Or make -j <number-of-cores-you-want-to-use>
make modules-j $(nproc)
```
Run the following as root
```bash
make INSTALL_MOD_STRIP=1 modules_install
make install
depmod
update-grub
# reboot
```

### Linux sysctl notes:
- After building custom kernel, run the following to check the spurious event `sysctl` property.
```bash
sysctl net.ipv4.tcp_spurious_wake # Default is 1
```
- To turn off spurious events, run the following as root:
```bash
sysctl -w net.ipv4.tcp_spurious_wake=0
```

### FreeBSD
In this guide you'll spin up a VM to build a kernel and get debugging symbols for GDB, and then re-run the VM to debug with GDB.
- First prepare a VM as build environment (use the scripts in `bsd_scripts` and `bsd_scripts/README.md` to make your life easier):

Run as user:
```
qemu-system-x86_64 -smp 16 -m 32768 -hda VM60G.raw -boot c -cdrom FreeBSD-13.0-RELEASE-amd64-dvd1.iso -net user -net nic
```

- Now buid the kernel:
    - To build the kernel, follow the handbook here: https://docs.freebsd.org/en/books/handbook/kernelconfig/#kernelconfig-building
    - Try to use the `MINIMAL` configuration of the kernel to save yourself some **SIGNIFICANT** time.
    - Before running `make`, remember to apply the `patch/kevent.patch`.
    - Make sure to enable debug symbols in your build.

And copy out the `kernel` and `kernel.symbols` file from `/boot/kernel` directory to the host machine.
Then shut the guest image down, and reboot with QEMU serial debugging enabled:

```
qemu-system-x86_64 -smp 16 -m 32768 -hda VM60G.raw -boot c -cdrom FreeBSD-13.0-RELEASE-amd64-dvd1.iso -net user,hostfwd=tcp::5000-:22 -net nic
```

When QEMU is "stopped" as displayed, open a separate terminal and use `gdb` in the host machine to connect to the guest:
```
gdb kernel
```

where the `kernel` above is the Freebsd kernel file copy out as mentioned earlier. Now followed by two statement below:
```
target remote localhost:1234
```


## Patches
Patches are located in the `patch` folder.
- `debian.patch` once applied to a **Debian** enables controlling spurious event-delivery from the TCP stack to Epoll system.
- `tiny_kernel.patch` works the same as the `debian.patch` but applies to **tiny kernel**.
- `kevent.patch` supresses spurious notifications by the TCP stack to the Kevent system. It is applied to the FreeBSD kernel (tested on FreeBSD 13.0)

Recommended process to apply a patch:
```bash
cd <kernel-source>
git apply --stat <path to .patch file>
git apply --check <path to .patch file>
git am < <path to .patch file>
```

## Userspace apps:
You'll find the following in the `apps` folder:
- `epolltest.c` is to test spurious notifications from the network/TCP/IP stack to epoll/kevent.
- `kq.c` is to familiarize yourself with BSD Kevents.

## Notes:
- Running the `epolltest.c` user-space app, try with and without self-client.
- Running `epolltest.c` will likely result in different behaviour between Linux and FreeBSD. This is due to the poor performance of the localhost network in FreeBSD.
