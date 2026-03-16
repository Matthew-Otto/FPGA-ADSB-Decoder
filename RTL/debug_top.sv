// poor man's ILA
// button 1 to start capture
// button 2 to dump over uart

module debug_top (
    input  logic       clk0,
    input  logic       btn1,
    input  logic       btn2,

    output logic       uart_tx,
    output logic       probe,

    input  logic       samp_clk,
    input  logic [7:0] i,
    input  logic [7:0] q,

    output logic [5:0] led
);

    /////////////////////////////////
    //// user IO ////////////////////
    /////////////////////////////////

    logic btn1_db;
    logic btn2_db;

    debounce #(
        .CLK_FREQ(100000000),
        .PULSE(1)
    ) db_1 (
        .clk(clk0),
        .db_in(btn1),
        .db_out(btn1_db)
    );
    debounce #(
        .CLK_FREQ(100000000),
        .PULSE(1)
    ) db_2 (
        .clk(clk0),
        .db_in(btn2),
        .db_out(btn2_db)
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
    
    assign reset = reseti;

    /////////////////////////////////
    //// end reset //////////////////
    /////////////////////////////////


    logic sample_valid;
    logic signed [7:0] i_samp, q_samp;
    logic [7:0] i_nodc, q_nodc;

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
    // convert samples to magnitude (^2)
    assign mag2 = i_samp * i_samp + q_samp * q_samp;

    // Remove DC component
    dc_block #(
        .WIDTH(8),
        .K(10)
    ) db_block_i (
        .clk(clk0),
        .reset(reset),
        .sample_valid(sample_valid),
        .sample_in(i_samp),
        .sample_out(i_nodc)
    );
    dc_block #(
        .WIDTH(8),
        .K(10)
    ) db_block_q (
        .clk(clk0),
        .reset(reset),
        .sample_valid(sample_valid),
        .sample_in(q_samp),
        .sample_out(q_nodc)
    );

    ///////////////////////////////////////////////////////////////////////
    //// DEBUG logic //////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////

    localparam SAMPLE_CNT = 40000;
    localparam CNT_WIDTH = $clog2(SAMPLE_CNT);

    logic [CNT_WIDTH-1:0] cnt, next_cnt;

    logic [7:0] read_i, read_q;
    logic dump_i;
    logic wr_en;

    logic uart_ready;
    logic uart_valid;


    enum {
        IDLE,
        CAPTURE,
        DUMP
    } state, next_state;


    always_ff @(posedge clk0) begin
        if (reset) state <= IDLE;
        else       state <= next_state;

        cnt <= next_cnt;
    end

    always_comb begin
        next_state = state;
        next_cnt = cnt;
        led = '1;
        wr_en = 0;
        uart_valid = 0;

        led[3] = samp_clk;

        case (state)
            IDLE : begin
                next_cnt = 0;
                if (btn1_db) next_state = CAPTURE;
                if (btn2_db) next_state = DUMP;
            end

            CAPTURE : begin
                led[0] = 1'b0;
                
                if (sample_valid) begin
                    wr_en = 1;
                    next_cnt = cnt + 1;

                    if (cnt == (SAMPLE_CNT-1))
                        next_state = IDLE;
                end

            end
            
            DUMP : begin
                led[5] = 1'b0;
                uart_valid = 1;

                led[4:0] = ~cnt[6:2];

                if (uart_ready) begin
                    if (dump_i)
                        next_cnt = cnt + 1;
                    if (cnt == (SAMPLE_CNT-1))
                        next_state = IDLE;
                end
            end

            default : next_state = IDLE;
        endcase
    end

    ///////////////////////////////////////////////////////////////////////
    //// BRAM /////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////

    logic [15:0] ram [SAMPLE_CNT-1:0];

    always_ff @(posedge clk0) begin
        if (wr_en)
            ram[cnt] <= {i_nodc,q_nodc};
        
        {read_i,read_q} <= ram[cnt];
    end

    always_ff @(posedge clk0) begin
        if (state == IDLE)
            dump_i <= 0;
        else if (state == DUMP && uart_ready)
            dump_i <= ~dump_i;
    end


    ///////////////////////////////////////////////////////////////////////
    //// end DEBUG logic //////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////

    logic [7:0] uart_data;
    assign uart_data = dump_i ? read_i : read_q;

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
        .data(uart_data)
    );

endmodule