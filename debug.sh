KERNEL_VER="v5.11"
CPU_CORES="4"
MEMORY="4000M"
app_cc="cc"
DEVROOT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ARCH=$(arch)

if [[ $ARCH == "x86_64" ]] || [[ $ARCH == "amd64" ]]; then
	DISK_IMAGE=linux/arch/x86/boot/bzImage
elif [[ $ARCH == "aarch64" ]] || [[ $ARCH == "arm64" ]]; then
	DISK_IMAGE=linux/arch/arm64/boot/Image
fi

# Go to kernel_dev project root
cd $DEVROOT

# Get sources
echo -n -e "Fetching buildroot source... \t\t\t"
if [[ -d buildroot ]]; then
		echo "done!"
else
		git clone https://github.com/buildroot/buildroot.git
fi

echo -n -e "Fetching kernel $KERNEL_VER source... \t\t\t"
if [[ -d linux ]]; then
		echo "done!"
else
		git clone https://github.com/torvalds/linux.git
		cd linux
		git checkout $KERNEL_VER
		cd ..
fi

# Copy configs
cp configs/linux.config linux/.config
cp configs/br.config buildroot/.config

# Add apps
mkdir -p buildroot/overlay/apps/
if [[ $1 == "--bsd" ]]; then
	shift
	cp apps/BSD/* buildroot/overlay/apps/
else
	cp apps/Linux/* buildroot/overlay/apps/
fi


# Compile apps
echo -n -e "Compiling and adding user apps... \t\t"
for i in buildroot/overlay/apps/??*.c ; do
	$app_cc $i -o $i.out;
done
echo "done!"

# Compile linux
echo -n -e "Compiling kernel... \t\t\t\t"
cd linux
yes "" | CC="ccache gcc" make -j$(nproc) # &> /tmp/linux_compile.log
echo "done! (log at /tmp/linux_compile.log)"
cd ..

if [[ ! -f buildroot/output/images/rootfs.ext4 ]]; then
	# Compile buildroot (build rootfs image)
	echo -n -e "Building rootfs image... \t\t\t"
	cd buildroot
	yes "" | CC="ccache gcc" make -j$(nproc) &> /tmp/br_compile.log
	echo "done! (log at /tmp/br_compile.log)"
	cd ..
else
	echo "Found rootfs image!"
fi

# Copy/Add init scripts to buildroot
if [[ ! -f buildroot/overlay/etc/init.d/Stest_init ]]; then
	echo -n -e "Adding init scripts... \t\t\t"
	mkdir -p buildroot/overlay/etc/init.d
	cp buildroot/output/target/etc/init.d/* buildroot/overlay/etc/init.d/
	echo "for i in /apps/??*.out ;do \$i start; done" > buildroot/overlay/etc/init.d/Stest_init
	chmod 777 buildroot/overlay/etc/init.d/Stest_init
	echo "done!"

	# Recompile buildroot (build rootfs image)
	echo -n -e "Re-building rootfs image... \t\t\t"
	cd buildroot
	yes "" | CC="ccache gcc" make -j$(nproc) &> /tmp/br_compile.log
	echo "done! (log at /tmp/br_recompile.log)"
	cd ..
fi

# Save old configs and copy-back working configs so we don't answer questions every damn time
cp configs/linux.config configs/linux.config.bak
cp configs/br.config configs/br.config.bak
cp linux/.config configs/linux.config
cp buildroot/.config configs/br.config

echo "Done building!"

if [[ $1 == "--only-build" ]]; then
	exit 0
fi

echo "qemu-system-x86_64 -kernel $DISK_IMAGE -boot c -smp $CPU_CORES -m $MEMORY -drive file=buildroot/output/images/rootfs.ext4,format=raw -append \"root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr\" -serial stdio -display none"
exit 0

if [[ $1 == "--no-tmux" ]]; then
	echo "Running QEMU..."
	if [[ $2 == "--no-debug" ]]; then
		qemu-system-x86_64 -kernel $DISK_IMAGE -boot c -smp $CPU_CORES -m $MEMORY -drive file=buildroot/output/images/rootfs.ext4,format=raw -append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" -serial stdio -display none
	else
		qemu-system-x86_64 -s -S -kernel $DISK_IMAGE -boot c -smp $CPU_CORES -m $MEMORY -drive file=buildroot/output/images/rootfs.ext4,format=raw -append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" -serial stdio -display none
	fi
else
	tmux \
    	new-session  "qemu-system-x86_64 -s -S -kernel $DISK_IMAGE -boot c -smp $CPU_CORES -m $MEMORY -drive file=buildroot/output/images/rootfs.ext4,format=raw -append \"root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr\" -serial stdio -display none" \; \
    	split-window "gdb -q linux/vmlinux -ex 'target remote :1234'" \;
fi
