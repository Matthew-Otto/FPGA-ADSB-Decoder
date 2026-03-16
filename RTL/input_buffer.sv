module input_buffer (
    input  logic core_clk,
    input  logic core_rst,

    input  logic sample_clk,

    input  logic [7:0] sample_i_in,
    input  logic [7:0] sample_q_in,

    output logic [7:0] sample_i_out,
    output logic [7:0] sample_q_out,

    output logic valid_out
);

    // Generate IDDR primitives to force IOB placement
`ifdef SYNTHESIS
    genvar i;
    generate
    for (i = 0; i < 8; i = i + 1) begin : IO_buffer_gen
        IDDR iddr_inst_i (
            .Q0(i_buf[i]), // Data captured on rising edge
            .Q1(), // Data captured on falling edge
            .D(sample_i_in[i]),    // Direct connection to the physical pin
            .CLK(sample_clk)
        );
        IDDR iddr_inst_q (
            .Q0(), // Data captured on rising edge
            .Q1(q_buf[i]), // Data captured on falling edge
            .D(sample_q_in[i]),    // Direct connection to the physical pin
            .CLK(sample_clk)
        );
    end
    endgenerate
`else
    assign i_buf = sample_i_in;
    assign q_buf = sample_q_in;
`endif


    logic [7:0]  i_buf, q_buf;
    logic [15:0] packed_buf;
    logic [15:0] packed_buf_sync;

    assign packed_buf = {i_buf,q_buf};

    async_fifo #(
        .ADDR_WIDTH(2),
        .DATA_WIDTH(16)
    ) cdc_fifo_i (
        .clk_in(sample_clk),
        .clk_out(core_clk),
        .reset(core_rst),
        .ready_in(),
        .valid_in(1'b1),
        .data_in(packed_buf),
        .ready_out(1'b1),
        .valid_out(valid_out),
        .data_out(packed_buf_sync)
    );

    assign {sample_i_out,sample_q_out} = packed_buf_sync;

endmodule : input_buffer
