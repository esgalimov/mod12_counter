iverilog mod12_counter.v testbench.v -o mod12_counter

if [ "$?" = "0" ]; then
    ./mod12_counter
    gtkwave dump.vcd
fi