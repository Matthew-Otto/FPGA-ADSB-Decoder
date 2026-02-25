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

    logic sample_clk_buf;
    assign sample_clk_buf = sample_clk;

    logic [7:0]  i_buf, q_buf;
    logic [15:0] packed_buf;
    logic [15:0] packed_buf_sync;

    always_ff @(posedge sample_clk_buf) begin
        i_buf <= sample_i_in;
        q_buf <= sample_q_in;
    end

    assign packed_buf = {i_buf,q_buf};

    async_fifo #(
        .ADDR_WIDTH(3),
        .DATA_WIDTH(16)
    ) cdc_fifo_i (
        .clk_in(sample_clk_buf),
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
