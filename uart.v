`timescale 1ns/1ps

module uart_core(
    input clk,
    input rst,
    input i_wr,
    input [7:0] i_data,
    input i_rx,
    output reg o_tx,
    output reg o_busy,
    output reg [7:0] o_rx_data,
    output reg o_rx_valid
);

    // Simplified Clocks per Baud for fast simulation
    parameter CLKS_PER_BAUD = 10; 

    // --- TRANSMITTER FSM ---
    reg [3:0] tx_state;
    reg [3:0] tx_bit_idx;
    reg [7:0] tx_data_reg;
    reg [31:0] tx_clk_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_tx <= 1'b1; // Idle state is HIGH
            o_busy <= 1'b0;
            tx_state <= 0;
            tx_clk_cnt <= 0;
        end else begin
            case (tx_state)
                0: begin // IDLE STATE
                    if (i_wr) begin
                        tx_data_reg <= i_data;
                        o_busy <= 1'b1;
                        o_tx <= 1'b0; // Send Start Bit (LOW)
                        tx_state <= 1;
                        tx_clk_cnt <= 0;
                        tx_bit_idx <= 0;
                    end else begin
                        o_tx <= 1'b1;
                        o_busy <= 1'b0;
                    end
                end
                1: begin // DATA SHIFTING STATE
                    if (tx_clk_cnt < CLKS_PER_BAUD - 1) begin
                        tx_clk_cnt <= tx_clk_cnt + 1;
                    end else begin
                        tx_clk_cnt <= 0;
                        if (tx_bit_idx < 8) begin
                            o_tx <= tx_data_reg[tx_bit_idx]; // Send LSB first
                            tx_bit_idx <= tx_bit_idx + 1;
                        end else if (tx_bit_idx == 8) begin
                            o_tx <= 1'b1; // Send Stop Bit (HIGH)
                            tx_bit_idx <= tx_bit_idx + 1;
                        end else begin
                            tx_state <= 0; // Return to IDLE
                        end
                    end
                end
            endcase
        end
    end

    // --- RECEIVER FSM ---
    reg [3:0] rx_state;
    reg [3:0] rx_bit_idx;
    reg [31:0] rx_clk_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_rx_valid <= 1'b0;
            o_rx_data <= 8'h00;
            rx_state <= 0;
            rx_clk_cnt <= 0;
        end else begin
            o_rx_valid <= 1'b0; // Pulse high for 1 clock cycle when done
            case (rx_state)
                0: begin // IDLE WAIT FOR START BIT
                    if (i_rx == 1'b0) begin 
                        rx_clk_cnt <= 0;
                        rx_state <= 1;
                    end
                end
                1: begin // WAIT HALF BAUD (Sample the center of the bit)
                    if (rx_clk_cnt < (CLKS_PER_BAUD / 2) - 1) begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end else begin
                        if (i_rx == 1'b0) begin // Verify it is a true start bit, not noise
                            rx_clk_cnt <= 0;
                            rx_state <= 2;
                            rx_bit_idx <= 0;
                        end else begin
                            rx_state <= 0;
                        end
                    end
                end
                2: begin // RECEIVE DATA BITS
                    if (rx_clk_cnt < CLKS_PER_BAUD - 1) begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end else begin
                        rx_clk_cnt <= 0;
                        o_rx_data[rx_bit_idx] <= i_rx; // Read the bit
                        if (rx_bit_idx < 7) begin
                            rx_bit_idx <= rx_bit_idx + 1;
                        end else begin
                            rx_state <= 3; // Wait for Stop Bit
                        end
                    end
                end
                3: begin // STOP BIT
                    if (rx_clk_cnt < CLKS_PER_BAUD - 1) begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end else begin
                        o_rx_valid <= 1'b1; // Signal that a full byte is ready!
                        rx_state <= 0;
                    end
                end
            endcase
        end
    end
endmodule
