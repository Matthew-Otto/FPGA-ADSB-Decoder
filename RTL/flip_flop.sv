module flip_flop #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

    always_ff @(posedge clk) begin
        q <= d;
    end

endmodule : flip_flop
