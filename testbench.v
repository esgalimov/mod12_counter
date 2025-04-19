`timescale 1 us / 100 ns

module testbench;

    // Тактовый и сброс
    reg clk = 1'b0;
    reg reset_n = 0;

    // Интерфейсы верхнего уровня
    wire [7:0] led;
    wire [6:0] seg;
    wire [1:0] digit;
    wire spi_mosi;
    wire spi_clk;
    wire spi_cs;

    // Генерация тактового сигнала (1 МГц)
    always #1 clk = ~clk; // Период 2 мкс → частота 500 кГц

    // Инстанцирование тестируемого модуля
    top dut (
        .clk(clk),
        .reset_n(reset_n),
        .led(led),
        .seg(seg),
        .digit(digit),
        .spi_mosi(spi_mosi),
        .spi_clk(spi_clk),
        .spi_cs(spi_cs)
    );

    initial begin
        $dumpfile("dump.vcd"); // <-- ОБЯЗАТЕЛЬНО
        $dumpvars(0, testbench); // Записываем все сигналы

        $display("Test started...");

        // Подаём сброс на старте
        reset_n = 0;
        #5;
        reset_n = 1;

        // Имитируем работу ~1000 тактов (примерно 2 мс)
        #2000;

        $display("Test finished.");
        $finish;
    end

endmodule