// 24 bit ADS-B Mode S CRC

module crc24 (
    input  logic clk,
    input  logic reset,

    input  logic valid,
    input  logic data,

    output logic crc_error
);

    localparam logic [23:0] POLYNOMIAL = 24'hFFF409;

    logic [23:0] crc;

    assign crc_error = |crc;

    always_ff @(posedge clk) begin
        if (reset)
            crc <= 0;
        else if (valid) begin
            if (POLYNOMIAL[0])
                crc[0] <= data ^ crc[23];
            else
                crc[0] <= data;

            for (int i = 1; i < 24; i++) begin
                if (POLYNOMIAL[i])
                    crc[i] <= crc[i-1] ^ crc[23];
                else
                    crc[i] <= crc[i-1];
            end
        end
    end

endmodule : crc24
