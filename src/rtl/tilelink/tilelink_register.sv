// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module tilelink_register
    import tilelink_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    input  tl_h2d_t host_i,
    output tl_d2h_t host_o,
    output tl_h2d_t device_o,
    input  tl_d2h_t device_i
);

    tl_h2d_t host_q;
    tl_d2h_t device_q;

    logic request_stalled, response_stalled;
    assign request_stalled = device_o.a_valid && !device_i.a_ready;
    assign response_stalled = host_o.d_valid && !host_i.d_ready;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            host_q   <= '{a_opcode: Get, default: '0};
            device_q <= '{d_opcode: AccessAck, default: '0};
        end else begin
            if (!request_stalled) begin
                host_q <= host_i;
            end
            if (!response_stalled) begin
                device_q <= device_i;
            end
        end
    end

    always_comb begin
        host_o   = device_q;
        device_o = host_q;

        host_o.a_ready = !request_stalled;
        device_o.d_ready = !response_stalled;
    end

endmodule
