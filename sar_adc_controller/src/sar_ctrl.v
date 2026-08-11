/*
    Discrete Successive-Approximation ADC Controller
    DAC Control and SAR Block
    Written by Samyar Sadat Akhavi, 2026.
*/

module sar_ctrl (
    input start,
    input [7:0] comp_settle_clks,
    output reg conv_done,
    
    input sample_comp,
    output reg [7:0] dac_bits,
    input clk,
    input rst,
    input clken
);

    reg[2:0] curr_bit;
    reg[7:0] clks_count;

    localparam IDLE = 1'd0, RUN = 1'd1;
    reg state;

    always @(posedge clk) begin
        if (rst) begin
            // reset state
            conv_done <= 0;
            dac_bits  <= 0;
            state     <= IDLE;
        end else if (clken) begin
            conv_done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        // initial start state
                        curr_bit   <= 7;
                        dac_bits   <= 8'b10000000;
                        clks_count <= 0;
                        state      <= RUN;
                    end
                end
                RUN: begin
                    if (clks_count == comp_settle_clks) begin
                        // sample less than DAC voltage
                        if (!sample_comp)
                            dac_bits[curr_bit] <= 0;

                        if (curr_bit == 0) begin
                            conv_done <= 1;
                            state     <= IDLE;
                        end else begin
                            curr_bit <= curr_bit - 3'd1;  // new curr_bit will be available on next cycle
                            dac_bits[curr_bit - 1] <= 1;
                        end

                        clks_count <= 0;
                    end else begin
                        clks_count <= clks_count + 8'd1;
                    end
                end
            endcase
        end
    end

endmodule