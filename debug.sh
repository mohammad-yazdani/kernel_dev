KERNEL_VER="v5.4"
CPU_CORES="16"
MEMORY="16000M"
app_cc="cc"

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
cp apps/* buildroot/overlay/apps/

# Compile apps
echo -n -e "Compiling and adding user apps... \t\t"
for i in buildroot/overlay/apps/??*.c ; do
	$app_cc $i -o $i.out;
done
echo "done!"

# Compile linux
echo -n -e "Compiling kernel... \t\t\t\t"
cd linux
CC="ccache gcc" make -j 32 &> /tmp/linux_compile.log
echo "done! (log at /tmp/linux_compile.log)"
cd ..

# Compile buildroot (build rootfs image)
echo -n -e "Building rootfs image... \t\t\t"
cd buildroot
CC="ccache gcc" make -j 32 &> /tmp/br_compile.log
echo "done! (log at /tmp/br_compile.log)"
cd ..

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
	CC="ccache gcc" make -j 32 &> /tmp/br_compile.log
	echo "done! (log at /tmp/br_recompile.log)"
	cd ..
fi

tmux \
    new-session  "qemu-system-x86_64 -s -S -kernel linux/arch/x86/boot/bzImage -boot c -smp $CPU_CORES -m $MEMORY -drive file=buildroot/output/images/rootfs.ext4 -append \"root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr\" -serial stdio -display none" \; \
    split-window "gdb -q linux/vmlinux -ex 'target remote :1234'" \;
