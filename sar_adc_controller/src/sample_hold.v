/*
    Discrete Successive-Approximation ADC Controller
    Sample and Hold Analog Switch Control Block
    Written by Samyar Sadat Akhavi, 2026.
*/

module sample_hold (
    input start,
    input [7:0] sample_clks,
    output reg sample_done,
    input enabled,
    
    output sample_sw_nen,
    input clk,
    input rst,
    input clken
);

    reg[7:0] clks_count;
    reg switch_en;
    assign sample_sw_nen = !switch_en;

    localparam IDLE = 1'd0, SAMPLE = 1'd1;
    reg state;

    always @(posedge clk) begin
        if (rst) begin
            // reset state
            sample_done <= 0;
            switch_en   <= 0;
            state       <= IDLE;
        end else if (clken) begin
            if (!enabled) begin
                // sample hold disabled
                sample_done <= 1;
                switch_en   <= 1;
                state       <= IDLE;
            end else begin
                // sample hold enabled
                sample_done <= 0;

                case (state)
                    IDLE: begin
                        if (start) begin
                            // initial start state
                            clks_count <= 0;
                            switch_en  <= 1;
                            state      <= SAMPLE;
                        end
                    end
                    SAMPLE: begin
                        if (clks_count == sample_clks) begin
                            switch_en   <= 0;
                            sample_done <= 1;
                            state       <= IDLE;
                        end else begin
                            clks_count <= clks_count + 8'd1;
                        end
                    end
                endcase
            end
        end
    end

endmodule