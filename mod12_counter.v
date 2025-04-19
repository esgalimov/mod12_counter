// =======================================================
// TOP MODULE: Счетчик по модулю 12 с параллельным переносом
// =======================================================
module top (
    input wire clk,
    input wire reset_n,
    output wire [7:0] led,
    output wire [6:0] lseg,
    output wire [6:0] hseg,
    output wire spi_mosi,
    output wire spi_clk,
    output wire spi_cs
);

    wire reset = ~reset_n;
    wire [3:0] count;
    wire carry;

    counter12 counter_inst (
        .clk(clk),
        .reset(reset),
        .count(count),
        .carry(carry)
    );

    assign led = {4'b0, count};

    seg7 seg7_inst (
        .clk(clk),
        .reset(reset),
        .value(count),
        .lseg(lseg),
        .hseg(hseg)
    );

    spi_dac dac_inst (
        .clk(clk),
        .reset(reset),
        .data({4'b0, count}),
        .mosi(spi_mosi),
        .sclk(spi_clk),
        .cs(spi_cs)
    );

endmodule


// =======================================================
// СЧЕТЧИК ПО МОДУЛЮ 12 С ПАРАЛЛЕЛЬНЫМ ПЕРЕНОСОМ
// =======================================================
module counter12(
    input  wire clk,
    input  wire reset,
    output reg  [3:0] count,
    output wire carry
);

    wire [3:0] next_count = (count == 11) ? 4'd0 : count + 1;
    assign carry = (count == 11);

    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 4'd0;
        else
            count <= next_count;
    end
endmodule


// =======================================================
// МУЛЬТИПЛЕКСОР ДЛЯ 7-СЕГМЕНТНОГО ИНДИКАТОРА (2 РАЗРЯДА)
// =======================================================
module seg7(
    input wire clk,
    input wire reset,
    input wire [3:0] value,
    output reg [6:0] lseg,
    output reg [6:0] hseg
);

    reg [3:0] ones, tens;

    always @(*) begin
        ones = value % 10;
        tens = value / 10;

        case (ones)                     // hex       maybe (invert)
            4'd0: lseg = 7'b1000000;    // 40            011 1111
            4'd1: lseg = 7'b1111001;    // 79            000 0110
            4'd2: lseg = 7'b0100100;    // 24            101 1011
            4'd3: lseg = 7'b0110000;    // 30            100 1111
            4'd4: lseg = 7'b0011001;    // 19            110 0110
            4'd5: lseg = 7'b0010010;    // 12            110 1101
            4'd6: lseg = 7'b0000010;    // 02            111 1101
            4'd7: lseg = 7'b1111000;    // 78            000 0111
            4'd8: lseg = 7'b0000000;    // 00            111 1111
            4'd9: lseg = 7'b0010000;    // 10            110 1111
            default: lseg = 7'b1111111; // 7F            000 0000
        endcase

        case (tens)
            4'd0: hseg = 7'b1000000;    // 0111111
            4'd1: hseg = 7'b1111001;    // 0000110
            default: hseg = 7'b1111111; // 0000000
        endcase
    end
endmodule


// =======================================================
// SPI-КОНТРОЛЛЕР ДЛЯ DAC (например, AD7302)
// =======================================================
module spi_dac (
    input wire clk,
    input wire reset,
    input wire [7:0] data,
    output reg mosi,
    output reg sclk,
    output reg cs
);
    reg [3:0] bit_cnt = 0;
    reg [7:0] shift_reg;
    reg [15:0] clk_div;
    localparam DIV = 50;

    parameter IDLE = 2'b00;
    parameter LOAD = 2'b01;
    parameter TRANSFER = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            clk_div <= 0;
            cs <= 1;
            sclk <= 0;
            mosi <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div == DIV) begin
                clk_div <= 0;
                case (state)
                    IDLE: begin
                        cs <= 1;
                        sclk <= 0;
                        next_state <= LOAD;
                    end
                    LOAD: begin
                        shift_reg <= data;
                        bit_cnt <= 7;
                        cs <= 0;
                        next_state <= TRANSFER;
                    end
                    TRANSFER: begin
                        mosi <= shift_reg[7];
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        sclk <= ~sclk;
                        if (bit_cnt == 0)
                            next_state <= IDLE;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                endcase
                state <= next_state;
            end
        end
    end
endmodule
