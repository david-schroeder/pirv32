# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors
# Modified by David Schröder 2026

from pydesignflow import Block, task, Result
from .tools import vivado
import subprocess

class Sources(Block):
    """Hardware sources"""

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"

    @task(requires={
        'swinit': 'swinit.build',
        }, always_rebuild=True, hidden=True)
    def srcs(self, cwd, swinit):
        """RTL + verification sources"""
        r = Result()

        design_srcs_pkg = []
        for d in ["fpga"]:
            design_srcs_pkg += [x for x in self.src_dir.glob(f"rtl/{d}/pkg/*.sv")]
        design_srcs = []
        design_srcs += [x for x in self.src_dir.glob("rtl/*/*.sv")]
        design_srcs += [x for x in self.src_dir.glob("rtl/*/*.v")]

        r.tb_srcs = [x for x in self.src_dir.glob("tb/*.sv")]
        r.tb_srcs += [vivado.vivado_dir() / "data/verilog/src/glbl.v"]

        r.design_srcs = design_srcs_pkg + design_srcs
        r.defines = { 'INIT_MEM_FILE': swinit.mem }
        r.include_dirs = []
        r.xcis = []

        return r

    @task(requires={"srcs":".srcs"})
    def lint(self, cwd, srcs):
        """Run static code quality assessment"""
        rules = [
            'always-comb',
            'always-comb-blocking',
            'always-ff-non-blocking',
            'case-missing-default',
            'explicit-function-lifetime',
            'explicit-function-task-parameter-type',
            'explicit-parameter-storage-type',
            'explicit-task-lifetime',
            'forbid-consecutive-null-statements',
            'forbid-defparam',
            'forbid-line-continuations',
            'generate-label',
            'module-begin-block',
            'module-filename',
            'module-parameter',
            'module-port',
            'one-module-per-file',
            'package-filename',
            'packed-dimensions-range-ordering',
            #'port-name-suffix',
            'undersized-binary-literal',
            'v2001-generate-begin',
            'void-cast',
        ]
        # Don't lint verilog files
        lint_srcs = [fn for fn in srcs.design_srcs if fn.suffix != '.v']
        try:
            subprocess.check_call(['verible-verilog-lint', '--ruleset', 'none', '--rules', ",".join(rules)]+lint_srcs, cwd=cwd)
        except subprocess.CalledProcessError as e:
            print(f"WARNING: verible-verilog-lint returned {e.returncode} errors.")
        else:
            print("Lint returned no errors.")
