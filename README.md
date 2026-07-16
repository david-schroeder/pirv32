32-bit RISC-V CPU Core
======================

(REUSE / Documentation badges go here)

This CPU is an in-order, 5-stage RV32IM design aimed at fixing the issues caused by other cores in the [RISC-V Lab](https://github.com/tub-msc/rvlab).

Target spec:
- Single-issue, in-order
- Instantiated in demo SoC (`src/rtl/nanosoc`)
- RV32GC instruction set support (currently: RV32IM)
- Linux-capable (currently: not)

This project is based on my [FPGA Project Skeleton](https://github.com/david-schroeder/fpga-framework).
