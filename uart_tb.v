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

    // --- REUSABLE TASK TO SEND AND RECEIVE A CHARACTER ---
    task send_and_receive;
        input [7:0] char_to_send;
        begin
            // 1. Wait until transmitter is completely idle
            wait(o_busy == 1'b0);
            
            // 2. Load data and trigger transmission
            i_data = char_to_send;
            i_wr = 1;        
            #20;             // Hold strobe for 1 clock cycle
            i_wr = 0;        
            
            // 3. Wait for the Receiver to successfully catch it
            wait(o_rx_valid == 1'b1);
            $display("SUCCESS: Receiver caught data -> '%c' (0x%h)", o_rx_data, o_rx_data);
            
            // 4. Small buffer delay before the next transmission
            #200; 
        end
    endtask

    initial begin
        // Tell Icarus Verilog to record signals for GTKWave
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, tb_uart);

        // Initialize & Reset
        clk = 0;
        rst = 1;
        i_wr = 0;
        i_data = 0;

        #100;
        rst = 0; // Release reset
        #20;

        $display("TEST: Sending word 'HELLO' into Transmitter...\n");
        
        // Transmit "HELLO" using ASCII Hex codes
        send_and_receive(8'h48); // 'H'
        send_and_receive(8'h45); // 'E'
        send_and_receive(8'h4C); // 'L'
        send_and_receive(8'h4C); // 'L'
        send_and_receive(8'h4F); // 'O'

        // Give it a little buffer time, then finish
        #500;
        $display("\nSimulation complete. Open 'waveform.vcd' in GTKWave.");
        $finish;
    end
    
endmodule
