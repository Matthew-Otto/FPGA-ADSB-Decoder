module top (
    input  logic       clk0,
    input  logic       btn1,

    output logic       uart_tx,

    input  logic       samp_clk,
    input  logic [7:0] i,
    input  logic [7:0] q,

    output logic probe,

    output logic [7:0] so,
    output logic [5:0] led
);

    logic reseti;
    logic reset;

    init_rst init_rst_i (
        .clk(clk0),
        .rst(reseti)
    );

    assign reset = btn1 | reseti;


    logic sample_valid;
    logic signed [7:0] i_samp, q_samp;

    logic [15:0] i2, q2;
    logic [15:0] mag2;

    // move SDR samples to clk0 domain
    input_buffer input_buffer_i (
        .core_clk(clk0),
        .core_rst(reset),
        .sample_clk(samp_clk),
        .sample_i_in(i),
        .sample_q_in(q),
        .sample_i_out(i_samp),
        .sample_q_out(q_samp),
        .valid_out(sample_valid)
    );

    assign so = i_samp;

    // convert samples to magnitude (^2)
    assign i2 = i_samp * i_samp;
    assign q2 = q_samp * q_samp;
    assign mag2 = i2 + q2;

    logic [7:0] decoded_byte;
    logic valid_decoded_byte;

    decode_adsb decode_i (
        .clk(clk0),
        .reset(reset),
        .sample(mag2),
        .valid_sample(sample_valid),
        .byte_stream(decoded_byte),
        .byte_stream_valid(valid_decoded_byte),
        .valid_cnt(led)
    );

    logic uart_ready;
    logic uart_valid;
    logic [7:0] uart_byte;

    fifo #(
        .WIDTH(8),
        .DEPTH(32)
    ) char_buffer (
        .clk(clk0),
        .reset(reset),
        .ready_in(),
        .valid_in(valid_decoded_byte),
        .data_in(decoded_byte),
        .ready_out(uart_ready),
        .valid_out(uart_valid),
        .data_out(uart_byte),
        .almost_full(),
        .almost_empty()
    );

    logic uart;
    assign uart_tx = uart;
    assign probe = uart;

    uart_tx #(
        .CLK_RATE(100000000),
        .BAUD_RATE(115200)
    ) uart_tx_i (
        .clk(clk0),
        .reset(reset),
        .tx(uart),
        .ready(uart_ready),
        .valid(uart_valid),
        .data(uart_byte)
    );

endmodule