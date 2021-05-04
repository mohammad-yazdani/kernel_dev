# BSD helper scripts
- `create.sh` creates a VM image and runs QEMU to install FreeBSD (Download `FreeBSD-13.0-RELEASE-amd64-disc1.iso` to this folder first).
- `debug.sh` uses two tmux panes to run the VM with `qemu` and debug with `gdb`.
- `run.sh` only runs the VM in a screen. Use this for non-debug work like code editing and configurations. It also opens an ssh port to the VM on port `5000`.
