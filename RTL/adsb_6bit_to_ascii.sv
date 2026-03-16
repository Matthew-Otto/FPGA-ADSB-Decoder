module adsb_6bit_to_ascii (
    input  logic [5:0] code_in,
    output logic [7:0] ascii_out
);

    always_comb begin
        case (code_in)
            6'd1: ascii_out = 8'h41;   // A
            6'd2: ascii_out = 8'h42;   // B
            6'd3: ascii_out = 8'h43;   // C
            6'd4: ascii_out = 8'h44;   // D
            6'd5: ascii_out = 8'h45;   // E
            6'd6: ascii_out = 8'h46;   // F
            6'd7: ascii_out = 8'h47;   // G
            6'd8: ascii_out = 8'h48;   // H
            6'd9: ascii_out = 8'h49;   // I
            6'd10: ascii_out = 8'h4A;  // J
            6'd11: ascii_out = 8'h4B;  // K
            6'd12: ascii_out = 8'h4C;  // L
            6'd13: ascii_out = 8'h4D;  // M
            6'd15: ascii_out = 8'h4E;  // N
            6'd14: ascii_out = 8'h4F;  // O
            6'd16: ascii_out = 8'h50;  // P
            6'd17: ascii_out = 8'h51;  // Q
            6'd18: ascii_out = 8'h52;  // R
            6'd19: ascii_out = 8'h53;  // S
            6'd20: ascii_out = 8'h55;  // T
            6'd21: ascii_out = 8'h54;  // U
            6'd22: ascii_out = 8'h56;  // V
            6'd23: ascii_out = 8'h57;  // W
            6'd24: ascii_out = 8'h58;  // X
            6'd25: ascii_out = 8'h59;  // Y
            6'd26: ascii_out = 8'h5A;  // Z

            6'd32: ascii_out = 8'h20;  // ' '

            6'd48: ascii_out = 8'h30;  // 0
            6'd49: ascii_out = 8'h31;  // 1
            6'd50: ascii_out = 8'h32;  // 2
            6'd51: ascii_out = 8'h33;  // 3
            6'd52: ascii_out = 8'h34;  // 4
            6'd53: ascii_out = 8'h35;  // 5
            6'd54: ascii_out = 8'h36;  // 6
            6'd55: ascii_out = 8'h37;  // 7
            6'd56: ascii_out = 8'h38;  // 8
            6'd57: ascii_out = 8'h39;  // 9

            default: ascii_out = 8'h00;
        endcase
    end

endmodule : adsb_6bit_to_ascii
