module square_signed_byte (
    input  logic clk,
    input  logic reset,

    input  logic [7:0]  signed_input,
    output logic [15:0] squared_output
);

    logic [15:0] sign_ext;

    assign sign_ext = {{8{signed_input[7]}},signed_input};

    assign squared_output = sign_ext * sign_ext;

endmodule : square_signed_byte
