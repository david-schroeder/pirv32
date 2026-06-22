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
        RS1,
        PC,
        ZERO
    } alu_src1_e;

    typedef enum logic [0:0] {
        RS2,
        IMM
    } alu_src2_e;

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

    typedef enum logic [2:0] {
        R_TYPE,
        I_TYPE,
        S_TYPE,
        B_TYPE,
        U_TYPE,
        J_TYPE
    } instr_type_e;

    typedef enum logic [1:0] {
        ALU,
        SHIFTER,
        DTIM,
        SEQ_PC
    } wb_src_e;

    typedef enum logic [2:0] {
        BEQ,
        BNE,
        BLT,
        BGE,
        BLTU,
        BGEU
    } branch_e;

endpackage
