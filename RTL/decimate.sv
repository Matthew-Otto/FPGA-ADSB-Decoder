module decimate #(
    parameter int DATA_WIDTH = 8,
    parameter int FACTOR = 2
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic [DATA_WIDTH-1:0] sample_in,
    input  logic                  sample_in_valid,
    output logic [DATA_WIDTH-1:0] sample_out,
    output logic                  sample_out_valid
);

    logic [$clog2(FACTOR)-1:0] valid_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_cnt <= 0;
        end else if (sample_in_valid) begin
            valid_cnt <= (valid_cnt == (FACTOR-1)) ? 0 : valid_cnt + 1;
        end
    end

    always_ff @(posedge clk)
        if (reset)
            sample_out_valid <= 0;
        else 
            sample_out_valid <= sample_in_valid && (valid_cnt == (FACTOR-1));

    always_ff @(posedge clk)
        if (reset)
            sample_out <= '0;
        else if (sample_in_valid && (valid_cnt == (FACTOR-1)))
            sample_out <= sample_in;

endmodule : decimate
