module pirv32_shifter
    import pirv32_pkg::*;
(
    input  logic [31:0] data_i,
    input  logic [ 4:0] shamt_i,
    input  shift_op_e   op_i,
    output logic [31:0] data_o
);

    logic [31:0] shifter_stages [5:0];
    assign shifter_stages[0] = data_i;

    generate
        for (genvar i = 1; i < 6; i++) begin : gen_shifter_stages
            localparam int SHIFT = 2**(i-1);
            always_comb begin
                unique casex ({shamt_i[i-1], op_i})
                    {1'b1, SLL}: begin
                        shifter_stages[i] = {shifter_stages[i-1][31-SHIFT:0], {SHIFT{1'b0}}};
                    end
                    {1'b1, SRL}: begin
                        shifter_stages[i] = {{SHIFT{1'b0}}, shifter_stages[i-1][31:SHIFT]};
                    end
                    {1'b1, SRA}: begin
                        shifter_stages[i] = {
                            {SHIFT{shifter_stages[i-1][31]}},
                            shifter_stages[i-1][31:SHIFT]
                        };
                    end
                    {1'b0, SLL},
                    {1'b0, SRL},
                    {1'b0, SRA}: shifter_stages[i] = shifter_stages[i-1];
                endcase
            end
        end : gen_shifter_stages
    endgenerate

    assign data_o = shifter_stages[5];

endmodule
