Jumps and Branches
==================

Jumps and branches are taken from the MEM stage. This reduces critical path length but unfortunately increases CPI fairly significantly. To alleviate this, the core currently includes a static not taken branch predictor, which will be replaced with a more advanced design featuring a BTB in the future.
