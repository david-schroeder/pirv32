FPGA Project Template
=====================

(REUSE / Documentation badges go here)

This repository contains a base framework for FPGA projects.
Specifically, it is geared towards endeavours involving software-capable RISC-V targets.
It is currently aimed at the Nexys Video FPGA board; it may be extended to other boards in the future.

To create a project based off of this one, fork this repository / copy its contents as a zip, then:
- Replace all instances of %PROJECT% in the repo with your project's name
- Rename any files or directories you deem necessary (`src/rtl/project` etc.)
- Adjust the top-level structure, XDC configuration etc. to your liking
- Build your project! The default documentation in *docs/* provides an overview of the built-in tooling (TBA).
  Generate its HTML via `make html` in the documentation directory.

This project is based off of the [TU Berlin's RISC-V Lab](https://github.com/tub-msc/rvlab).
