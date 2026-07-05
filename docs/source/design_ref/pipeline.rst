PIRV32 Pipeline
===============

The PIRV32 Core consists of a standard 5-stage pipeline, comprising the Fetch, Decode, Execute, Memory and Writeback stages respectively.

Stage control primarily happens via two signals per stage: `*_stage_valid` and `*_stage_ready`. The `valid` signal specifies whether the current stage is occupied by a RISC-V instruction (which is true even for illegal instructions), and thus whether the instruction is allowed to commit later. It is thus passed downstream from the fetch stage to the writeback stage, advancing by one stage per cycle. In contrast, the `ready` signals flow upstream from the writeback stage to the fetch stage. For any stage `X`, `X_stage_ready` being zero means that all stages from fetch until `X` will not update their pipeline registers in the next cycle, and that the stage after `X` will set its `valid` signal to zero in the next cycle (as a stalled stage's current instruction doesn't advance down the pipeline).
