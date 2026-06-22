onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider CPU
add wave -noupdate -label Regs /pirv32_core_tb/DUT/regfile_i/mem
add wave -noupdate -label DTIM /pirv32_core_tb/DUT/dtim_i/mem
add wave -noupdate /pirv32_core_tb/DUT/clk_i
add wave -noupdate /pirv32_core_tb/DUT/rst_ni
add wave -noupdate /pirv32_core_tb/DUT/rs1_o
add wave -noupdate /pirv32_core_tb/DUT/pc
add wave -noupdate /pirv32_core_tb/DUT/pc_seq
add wave -noupdate /pirv32_core_tb/DUT/pc_jump
add wave -noupdate /pirv32_core_tb/DUT/pc_d
add wave -noupdate /pirv32_core_tb/DUT/instr
add wave -noupdate /pirv32_core_tb/DUT/ra1
add wave -noupdate /pirv32_core_tb/DUT/ra2
add wave -noupdate /pirv32_core_tb/DUT/rd
add wave -noupdate /pirv32_core_tb/DUT/rs1
add wave -noupdate /pirv32_core_tb/DUT/rs2
add wave -noupdate /pirv32_core_tb/DUT/imm
add wave -noupdate /pirv32_core_tb/DUT/alu_a
add wave -noupdate /pirv32_core_tb/DUT/alu_b
add wave -noupdate /pirv32_core_tb/DUT/alu_src1
add wave -noupdate /pirv32_core_tb/DUT/alu_src2
add wave -noupdate /pirv32_core_tb/DUT/alu_op
add wave -noupdate /pirv32_core_tb/DUT/shift_op
add wave -noupdate /pirv32_core_tb/DUT/is_jump
add wave -noupdate /pirv32_core_tb/DUT/is_branch
add wave -noupdate /pirv32_core_tb/DUT/branch_type
add wave -noupdate /pirv32_core_tb/DUT/branch_decision
add wave -noupdate /pirv32_core_tb/DUT/dtim_op
add wave -noupdate /pirv32_core_tb/DUT/dtim_misaligned
add wave -noupdate /pirv32_core_tb/DUT/wb_data
add wave -noupdate /pirv32_core_tb/DUT/wb_we
add wave -noupdate /pirv32_core_tb/DUT/wb_src
add wave -noupdate /pirv32_core_tb/DUT/alu_res
add wave -noupdate /pirv32_core_tb/DUT/shiftout
add wave -noupdate /pirv32_core_tb/DUT/load_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {366085473 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 216
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {332896992 fs} {351576373 fs}
