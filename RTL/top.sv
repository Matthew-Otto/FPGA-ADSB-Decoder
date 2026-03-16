module top (
    input  logic       clk0,
    input  logic       clk2,
    input  logic       btn1,
    input  logic       btn2,

    output logic       uart_tx,

    input  logic       samp_clk,
    input  logic [7:0] i,
    input  logic [7:0] q,

    output logic probe,

    output logic [5:0] led
);

    /////////////////////////////////
    //// user IO ////////////////////
    /////////////////////////////////

    logic btn1_db;

    debounce #(
        .CLK_FREQ(100000000),
        .PULSE(1)
    ) db_1 (
        .clk(clk0),
        .db_in(btn1),
        .db_out(btn1_db)
    );
    /////////////////////////////////
    //// end user IO ////////////////
    /////////////////////////////////


    /////////////////////////////////
    //// reset //////////////////////
    /////////////////////////////////

    logic reseti;
    logic reset;

    init_rst init_rst_i (
        .clk(clk0),
        .rst(reseti)
    );

    assign reset = btn1_db | reseti;

    /////////////////////////////////
    //// end reset //////////////////
    /////////////////////////////////


    logic sample_valid;
    logic [7:0] i_samp, q_samp;
    logic [7:0] i_nodc, q_nodc;
    logic [7:0] i_abs, q_abs;
    logic [8:0] mag2;
        
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

    // Remove DC component
    dc_block #(
        .WIDTH(8),
        .K(18)
    ) db_block_i (
        .clk(clk0),
        .reset(reset),
        .sample_valid(sample_valid),
        .sample_in(i_samp),
        .sample_out(i_nodc)
    );
    dc_block #(
        .WIDTH(8),
        .K(18)
    ) db_block_q (
        .clk(clk0),
        .reset(reset),
        .sample_valid(sample_valid),
        .sample_in(q_samp),
        .sample_out(q_nodc)
    );

    // convert samples to magnitude mag = |i| + |q|
    assign i_abs = (i_nodc ^ {8{i_nodc[7]}}) + i_nodc[7];
    assign q_abs = (q_nodc ^ {8{q_nodc[7]}}) + q_nodc[7];

    assign mag2 = i_abs + q_abs;

    logic [8:0] decimated_sample;
    logic decimate_valid;

    decimate #(
        .FACTOR(4),
        .DATA_WIDTH(9)
    ) decimate_i (
        .clk(clk0),
        .reset(reset),
        .sample_in(mag2),
        .sample_in_valid(sample_valid),
        .sample_out(decimated_sample),
        .sample_out_valid(decimate_valid)
    );

    logic [7:0] decoded_byte;
    logic valid_decoded_byte;
    logic valid_packet;

    decode_adsb decode_i (
        .clk(clk0),
        .reset(reset),
        .sample(decimated_sample),
        .valid_sample(decimate_valid),
        .valid_packet(valid_packet),
        .byte_stream(decoded_byte),
        .byte_stream_valid(valid_decoded_byte)
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
        .BAUD_RATE(1000000)
    ) uart_tx_i (
        .clk(clk0),
        .reset(reset),
        .tx(uart),
        .ready(uart_ready),
        .valid(uart_valid),
        .data(uart_byte)
    );

    /////////////////////////////////
    //// Valid Packet Counter ///////
    /////////////////////////////////
    logic [5:0] led_cnt;
    always_ff @(posedge clk0) begin
        if (reset)
            led_cnt <= 0;
        else if (valid_packet)
            led_cnt <= led_cnt + 1;
    end

    assign led = ~led_cnt;

endmodule