# Kernel dev

## With tmux
- Simply run `debug.sh` :)
- I recommend reading the `debug.sh` script before using it, it's pretty short.

## With Visual Studio Code
1. Run `debug.sh --only-build` first so that you have access to kernel code.
2. Make a `.vscode` directory in the newly cloned `linux`:
```mkdir -p linux/.vscode```
3. Copy the two JSON files in `vscode` to `linux/.vscode`.
4. Open the `linux` folder in VSCode (not the `kernel_dev` project root).
5. You should have a debug option called `Debug kernel`, which debugs the kernel.
