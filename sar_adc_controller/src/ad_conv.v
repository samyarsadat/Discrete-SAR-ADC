/*
    Discrete Successive Approximate ADC Controller
    A/D Conversion Flow Control Block
    Written by Samyar Sadat Akhavi, 2026.
*/

module ad_conv (
    input clk,
    input rst,
    input clken,

    input sample_comp,
    output mux_nen, 
    output [7:0] dac_bits,

    input start_conv,
    output reg conv_started,
    output reg conv_done,
    output reg [7:0] output_latd,

    input [7:0] sample_clks,
    input [7:0] comp_settle_clks,
    input sh_enabled
);

    // sample hold controller
    reg sh_start;
    wire sh_done;

    sample_hold sh_ctrl(
        .start(sh_start),
        .sample_clks(sample_clks),
        .sample_done(sh_done),
        .enabled(sh_enabled),
        
        .sample_sw_nen(mux_nen),
        .clk(clk),
        .rst(rst),
        .clken(clken)
    );

    // SAR controller
    reg sar_start;
    wire sar_done;

    sar_ctrl sar_ctrl(
        .start(sar_start),
        .comp_settle_clks(comp_settle_clks),
        .conv_done(sar_done),
        
        .sample_comp(sample_comp),
        .dac_bits(dac_bits),
        .clk(clk),
        .rst(rst),
        .clken(clken)
    );

    // conversion flow
    localparam IDLE = 2'd0, SAMPLE = 2'd1, CONVERT = 2'd2;
    reg[1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            // reset state
            state        <= IDLE;
            sh_start     <= 0;
            sar_start    <= 0;
            conv_done    <= 0;
            conv_started <= 0;
            output_latd   = 0;
        end else if (clken) begin
            sh_start     <= 0;
            sar_start    <= 0;
            conv_done    <= 0;
            conv_started <= 0;
            
            case (state)
                IDLE: begin
                    if (start_conv) begin
                        conv_started <= 1;
                        sh_start     <= 1;
                        state        <= SAMPLE;
                    end
                end
                SAMPLE: begin
                    if (sh_done) begin
                        sar_start <= 1;
                        state     <= CONVERT;
                    end
                end
                CONVERT: begin
                    if (sar_done) begin
                        conv_done  <= 1;
                        state      <= IDLE;
                        output_latd = dac_bits;
                    end
                end
            endcase
        end
    end

endmodule