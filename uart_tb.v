`timescale 1ns/1ps

module tb_uart;

    // Testbench Variables
    reg clk;
    reg rst;
    reg i_wr;
    reg [7:0] i_data;
    wire i_rx;

    wire o_tx;
    wire o_busy;
    wire [7:0] o_rx_data;
    wire o_rx_valid;

    // Instantiate the UART Core
    uart_core uut (
        .clk(clk), 
        .rst(rst), 
        .i_wr(i_wr), 
        .i_data(i_data), 
        .i_rx(i_rx), 
        .o_tx(o_tx), 
        .o_busy(o_busy), 
        .o_rx_data(o_rx_data), 
        .o_rx_valid(o_rx_valid)
    );

    // ** LOOPBACK CONNECTION **
    // Connect Transmitter output wire directly back into Receiver input wire
    assign i_rx = o_tx;

    // Generate a 50MHz Clock
    always #10 clk = ~clk;

    initial begin
        // Tell Icarus Verilog to record signals for GTKWave
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, tb_uart);

        // 1. Initialize & Reset
        clk = 0;
        rst = 1;
        i_wr = 0;
        i_data = 0;

        #100;
        rst = 0; // Release reset
        #20;

        // 2. Start Transmission
        $display("TEST: Sending character 'A' (0x41) into Transmitter...");
        i_data = 8'h41;  // Hex for 'A'
        i_wr = 1;        // Trigger write strobe
        #20;
        i_wr = 0;        // Release write strobe

        // 3. Wait for the Receiver to catch it
        wait(o_rx_valid == 1'b1);
        $display("SUCCESS: Receiver caught data -> '%c' (0x%h)", o_rx_data, o_rx_data);

        // Give it a little buffer time, then finish
        #100;
        $display("Simulation complete. Open 'waveform.vcd' in GTKWave.");
        $finish;
    end
    
endmodule