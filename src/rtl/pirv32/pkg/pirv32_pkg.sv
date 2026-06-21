package pirv32_pkg;

    typedef enum logic [2:0] {
        ADD,
        SUB,
        XOR,
        AND,
        OR,
        SLT,
        SLTU
    } alu_op_e;

    typedef enum logic [1:0] {
        SLL,
        SRL,
        SRA
    } shift_op_e;

    typedef enum logic [2:0] {
        LB,
        LBU,
        LH,
        LHU,
        LW,
        SB,
        SH,
        SW
    } mem_op_e;

endpackage
