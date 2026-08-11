/*
    Discrete Successive Approximate ADC Controller
    Written by Samyar Sadat Akhavi, 2026.
*/

module top (
    // SYSTEM
    input sys_clk,
    input sys_nrst,

    // ADC INTERNAL
    input sample_comp,
    output mux_nen, 
    output [7:0] dac_bits,
    output [2:0] mux_bits,

    // HOST INTERFACE
    input scl,
    inout sda,
    output conv_done_pin
);

    reg sw_rst = 1;  // will trigger one reset at startup
    wire reset = !sys_nrst || sw_rst;

    // ADC clock enable
    // to prevent creating a new clock domain,
    // which would cause a number of synchronization issues,
    // we will use a slow enable signal to control certain ADC actions.
    reg adc_clken;
    reg[15:0] adc_clk_counter;
    wire[15:0] adc_clk_div;
    
    always @(posedge sys_clk) begin
        adc_clken <= 0;
        
        if (reset) begin
            adc_clk_counter <= 0;
        end else begin
            adc_clk_counter <= adc_clk_counter + 16'b1;
            
            if (adc_clk_counter == adc_clk_div) begin
                adc_clk_counter <= 0;
                adc_clken       <= 1;
            end
        end
    end

    // I2C comms
    wire status_writen;
    wire[7:0] sample_clks;
    wire[7:0] comp_settle_clks;
    wire[7:0] status_reg_write;
    wire[7:0] adc_result_reg;
    wire[7:0] status_reg_write_mask;
    reg[7:0] status_reg_read;

    /*
        ---- STATUS & COMMAND REGISTER MAP ----
        bits[2:0] -> (R/W) mux input select (0..7)
        bit[3]    -> ( /W) start conversion signal (will always read 0)
        bit[4]    -> (R/W) conversion done signal
        bit[5]    -> (R/W) enable sample hold
        bit[6]    -> ( /W) trigger reset (will always read 0)
        bit[7]    -> (R/W) enable conversion done singal output

        NOTES:
            - bit[3]: does not respect the write mask, as it is a one-shot request signal.
            - bit[4]: "done" flag can be cleared by writing a 0 to it.
            - bit[6]: does not respect the write mask, as it is a one-shot request signal.
    */

    i2cSlave i2c_slave(
        .clk(sys_clk),
        .rst(reset),
        .sda(sda),
        .scl(scl),

        .status_writen(status_writen),
        .status_reg_write_mask(status_reg_write_mask),  // R/W
        .status_reg_write(status_reg_write),            // W
        .status_reg_read(status_reg_read),              // R
        .adc_result_reg(adc_result_reg),                // R
        .sample_clks_reg(sample_clks),                  // R/W
        .comp_settle_clks_reg(comp_settle_clks),        // R/W
        .adc_clken_div_loreg(adc_clk_div[7:0]),         // R/W
        .adc_clken_div_hireg(adc_clk_div[15:8])         // R/W
    );

    // A/D conversion block
    assign mux_bits = status_reg_read[2:0];
    assign conv_done_pin = status_reg_read[7] ? !status_reg_read[4] : 1;  // active-low open-drain pin

    reg start_conv;
    wire conv_started;
    wire conv_done;

    ad_conv ad_conv(
        .clk(sys_clk),
        .rst(reset),
        .clken(adc_clken),

        .sample_comp(sample_comp),
        .mux_nen(mux_nen), 
        .dac_bits(dac_bits),

        .start_conv(start_conv),
        .conv_started(conv_started),
        .conv_done(conv_done),
        .output_latd(adc_result_reg),

        .sample_clks(sample_clks),
        .comp_settle_clks(comp_settle_clks),
        .sh_enabled(status_reg_read[5])
    );

    // register config handler
    localparam[7:0] STATUS_PROT_MASK = 8'b01001000;
    localparam[7:0] STATUS_RST_STATE = 8'b10100000;
    wire[7:0] status_write_mask = status_reg_write_mask & ~STATUS_PROT_MASK;
    reg[7:0] new_status_reg;
    reg status_written_flag;

    always @(posedge sys_clk) begin
        if (reset) begin
            // reset state
            start_conv          <= 0;
            status_reg_read     <= STATUS_RST_STATE;
            status_written_flag <= 0;
            sw_rst              <= 0;
        end else begin
            if (conv_started)
                start_conv <= 0;

            // STATUS REGISTER
            new_status_reg = status_reg_read;

            if (conv_done)
                new_status_reg[4] = 1;

            // status register is not updated until next cycle
            if (status_writen)
                status_written_flag <= 1;

            // I2C master has written to status register
            // (write was on previous cycle, new values can be read now)
            if (status_written_flag) begin
                status_written_flag <= 0;

                // software reset
                if (status_reg_write[6])
                    sw_rst <= 1;

                // write unprotected status bits, taking into account the user write mask
                new_status_reg = (new_status_reg & ~status_write_mask) | (status_reg_write & status_write_mask);

                // conversion start requested
                if (status_reg_write[3]) begin
                    start_conv       <= 1;
                    new_status_reg[4] = 0;
                end
            end

            status_reg_read <= new_status_reg;
        end
    end

endmodule