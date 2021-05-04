tmux new-session  "qemu-system-x86_64 -s -S -smp 16 -m 32768 -hda VM60G.raw -nographic -net user -net nic" \; \
    	split-window "gdb/bin/x86_64-unknown-freebsd-gdb -q vmbsd/kernel -ex 'target remote :1234'" \;

