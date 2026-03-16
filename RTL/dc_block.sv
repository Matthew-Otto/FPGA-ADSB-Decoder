// DC Block
// removes DC component from sample stream
// finds DC offset using a first order IIR low-pass filter and subtracts that from incoming samples.

module dc_block #(
    parameter WIDTH = 8,
    parameter K = 10 // alpha = 2^-K
) (
    input logic clk,
    input logic reset,

    input logic sample_valid,
    input logic signed [WIDTH-1:0] sample_in,
    output logic signed [WIDTH-1:0] sample_out
);

    logic signed [WIDTH-1:0] dc;
    logic signed [WIDTH+K-1:0] dc_ext;

    assign dc = dc_ext >>> K;
    assign sample_out = sample_in - dc;

    always_ff @(posedge clk) begin
        if (reset)
            dc_ext <= 0;
        else if (sample_valid)
            dc_ext <= dc_ext + sample_in - dc;
    end

endmodule : dc_block
