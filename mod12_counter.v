// =======================================================
// TOP MODULE: Счетчик по модулю 12 с параллельным переносом, 
// с индикацией состояние светодиодами, 
// 7-сегментным индикатором и цифроаналоговым преобразователем.
// =======================================================
module top (
    input wire clk,
    input wire reset_n,
    output wire [7:0] led,
    output wire [6:0] lseg,
    output wire [6:0] hseg,
    output wire [7:0] do
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

    assign do = count; // DAC

    seg7 seg7_inst (
        .clk(clk),
        .reset(reset),
        .value(count),
        .lseg(lseg),
        .hseg(hseg)
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
// 7-СЕГМЕНТНЫЙ ИНДИКАТОР (2 РАЗРЯДА)
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
            4'd0: hseg = 7'b1000000;    //               011 1111
            4'd1: hseg = 7'b1111001;    //               000 0110
            default: hseg = 7'b1111111; //               000 0000
        endcase
    end
endmodule
