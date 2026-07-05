Introduction
============

The Performant In-order RISC-V 32-bit CPU Core is currently an efficient RV32IM CPU aimed at embedded system environments. Future versions are intended to support full RV32GCSU, and thus operating systems.

The current ISA support is:
- RV32I base ISA
- M extension

Possibly the most important design goal is to be synthesizable / implementable on an FPGA (specifically, an XC7A200T) at a clock speed of 100MHz.
