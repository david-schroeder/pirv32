Multiplier
==========

The TURVo32 multiplier spans across three pipeline stages (EX, MEM and WB).
While allowing for high clock speeds, this means that an instruction following a multiply cannot use its result as an operand; in the event that this happens, the subsequent instruction stalls for a cycle (thus creating a 'multiply-use' conflict).
