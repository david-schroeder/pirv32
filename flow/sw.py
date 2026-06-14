# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors
# Modified by David Schröder 2026

from pydesignflow import Block, task, Result
from .tools.build_sw import build_sw, build_static_lib
from .tools.elf2mem import elfdelta

class Libsys(Block):
    """
    Shared system library including a small libc providing basic system functions such as printf, memcpy etc.
    """

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"

    @task(hidden=True)
    def build(self, cwd):
        """
        Builds library for static linking (.a).
        """
        r = Result()

        sw_dir = self.src_dir / "sw"
        sys_src_dir = sw_dir / "sys"
        sys_include_dir = sw_dir / "include"
        srcs = list(sys_src_dir.glob("*.c"))

        r.lib = cwd / "libsys.a"

        build_static_lib(cwd, srcs, r.lib,
            include_system=[
                sys_include_dir,
            ],
            include_quote=[],
        )

        return r

class Program(Block):
    """Program for a RISC-V CPU"""

    def __init__(self, name, **kwargs):
        """
        Args:
            name: Name of src/sw/ subdirectory containing program-specific
                sources files.
        """
        super().__init__(**kwargs)
        self.name = name

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"
        self.design_dir = self.src_dir / "design"

    @task(requires={
        'libsys':'libsys.build',
        }, hidden=True, always_rebuild=True)
    def build(self, cwd, libsys):
        """
        Main program for simulation and later use on FPGA.
        """
        r = Result()

        sw_dir = self.src_dir / "sw"
        ldscript = str(sw_dir / "link.ld")
        main_dir = sw_dir / self.name
        sys_include_dir = sw_dir / "include"

        srcs = []
        srcs += list(main_dir.glob("*.S"))
        srcs += list(main_dir.glob("*.c"))

        # Shared source files in sw/ folder:
        srcs += list(sw_dir.glob("*.S"))
        srcs += list(sw_dir.glob("*.c"))

        r.elf = cwd / "sw.elf"
        r.mem = cwd / "sw.mem"
        r.disasm = cwd / "sw.disasm"

        build_sw(
            cwd=cwd,
            srcs=srcs,
            ldscript=ldscript,
            output_elf_filename=r.elf,
            output_disasm_filename=r.disasm,
            output_mem_filename=r.mem,
            static_libs=[libsys.lib],
            include_system=[
                sys_include_dir,
            ],
            include_quote=[],
        )

        return r

    @task(requires={'build':'.build'})
    def run(self, cwd, build):
        """Run on FPGA (Not yet implemented)"""
        raise NotImplementedError("Not Implemented")
