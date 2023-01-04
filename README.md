# Single threaded http server in assembly that only prints "Hello assembly!"

# Build requirements
* 64-bit Linux
* GCC
* GNU binutils
* NASM assembler

# How to build

```console

$ make gnu # build GNU assembler version

$ make nasm # build NASM assembler version

```

# Refs

* Call conventions https://wiki.osdev.org/Calling_Conventions
* x64 Cheat Sheet https://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf
* Linux/System-V ABI https://wiki.osdev.org/System_V_ABI