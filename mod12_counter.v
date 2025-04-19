// =======================================================
// TOP MODULE: Счетчик по модулю 12 с параллельным переносом
// =======================================================
module top (
    input wire clk,
    input wire reset_n,
    output wire [7:0] led,
    output wire [6:0] seg,
    output wire [1:0] digit,
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

    seg7_mux seg7_inst (
        .clk(clk),
        .reset(reset),
        .value(count),
        .seg(seg),
        .digit(digit)
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
module seg7_mux(
    input wire clk,
    input wire reset,
    input wire [3:0] value,
    output reg [6:0] seg,
    output reg [1:0] digit
);

    reg toggle;
    reg [3:0] digit_lo, digit_hi;
    wire [6:0] seg_lo, seg_hi;

    always @(*) begin
        digit_lo = value % 10;
        digit_hi = value / 10;
    end

    bcd_to_7seg bcd_lo (.bcd(digit_lo), .seg(seg_lo));
    bcd_to_7seg bcd_hi (.bcd(digit_hi), .seg(seg_hi));

    always @(posedge clk or posedge reset) begin
        if (reset)
            toggle <= 0;
        else
            toggle <= ~toggle;
    end

    always @(*) begin
        if (toggle) begin
            seg = seg_hi;
            digit = 2'b10;
        end else begin
            seg = seg_lo;
            digit = 2'b01;
        end
    end
endmodule


// =======================================================
// ПРЕОБРАЗОВАТЕЛЬ BCD -> 7-СЕГМЕНТНЫЙ КОД
// =======================================================
module bcd_to_7seg (
    input wire [3:0] bcd,
    output reg [6:0] seg
);
    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b0111111; 
            4'd1: seg = 7'b0000110;
            4'd2: seg = 7'b1011011;
            4'd3: seg = 7'b1001111;
            4'd4: seg = 7'b1100110;
            4'd5: seg = 7'b1101101;
            4'd6: seg = 7'b1111101;
            4'd7: seg = 7'b0000111;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1101111;
            default: seg = 7'b0000000;
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
