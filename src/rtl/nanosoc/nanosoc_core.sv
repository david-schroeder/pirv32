// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// This is your project toplevel.

module nanosoc_core (
    input  logic clk_i, // 100MHz clock
    input  logic rst_ni,
    input  top_pkg::board2fpga_t io_i,
    output top_pkg::fpga2board_t io_o
);

    logic [ 7:0] led_q;
    // 5 updates / sec -> 20M cycles / update
    logic [24:0] counter_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            led_q     <= 8'b11000000;
            counter_q <= 25'd19999999;
        end else begin
            if (counter_q == '0) begin
                led_q     <= {led_q[0], led_q[7:1]};
                counter_q <= 25'd19999999;
            end else begin
                counter_q <= counter_q - 1;
            end
        end
    end

    always_comb begin
        io_o = '{default: '0};
        io_o.led = led_q;
    end

endmodule
