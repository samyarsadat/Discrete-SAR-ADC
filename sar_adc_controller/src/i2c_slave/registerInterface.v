//////////////////////////////////////////////////////////////////////
////                                                              ////
//// registerInterface.v                                          ////
////                                                              ////
//// This file is part of the i2cSlave opencores effort.          ////
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Author(s):                                                   ////
//// - Steve Fielding, sfielding@base2designs.com                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 Steve Fielding and OPENCORES.ORG          ////
//// Copyright (C) 2026 Samyar Sadat Akhavi                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE. See the GNU Lesser General Public License for more  ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from <http://www.opencores.org/lgpl.shtml>                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
`include "i2cSlave_define.v"


module registerInterface (
    clk,
    rst,
    addr,
    dataIn,
    writeEn,
    dataOut,
    
    status_reg_write_mask,  // R/W
    status_reg_write,       // W
    status_reg_read,        // R
    adc_result_reg,         // R
    sample_clks_reg,        // R/W
    comp_settle_clks_reg,   // R/W
    adc_clken_div_loreg,    // R/W
    adc_clken_div_hireg     // R/W
);

    input clk;
    input rst;
    input [7:0] addr;
    input [7:0] dataIn;
    input writeEn;
    output [7:0] dataOut;

    output [7:0] status_reg_write_mask;
    output [7:0] status_reg_write;
    input [7:0] status_reg_read;
    input [7:0] adc_result_reg;
    output [7:0] sample_clks_reg;
    output [7:0] comp_settle_clks_reg;
    output [7:0] adc_clken_div_loreg;
    output [7:0] adc_clken_div_hireg;

    reg [7:0] status_reg_write_mask;
    reg [7:0] status_reg_write;
    reg [7:0] sample_clks_reg;
    reg [7:0] comp_settle_clks_reg;
    reg [7:0] adc_clken_div_loreg;
    reg [7:0] adc_clken_div_hireg;

    reg [7:0] dataOut;

    // --- I2C Read
    always @(posedge clk) begin
        case (addr)
            8'h00: dataOut <= status_reg_write_mask;
            8'h01: dataOut <= status_reg_read;
            8'h02: dataOut <= sample_clks_reg;
            8'h03: dataOut <= comp_settle_clks_reg;
            8'h04: dataOut <= adc_clken_div_loreg;
            8'h05: dataOut <= adc_clken_div_hireg;
            8'h06: dataOut <= adc_result_reg;
            default: dataOut <= 8'h00;
        endcase
    end

    // --- I2C Write
    always @(posedge clk) begin
        if (rst) begin
            // reset state
            status_reg_write_mask <= 0;
            status_reg_write      <= 0;
            sample_clks_reg       <= 255;
            comp_settle_clks_reg  <= 255;
            adc_clken_div_loreg   <= 8'b11111111;
            adc_clken_div_hireg   <= 8'b00000001;  // 511
        end else if (writeEn == 1'b1) begin
            case (addr)
                8'h00: status_reg_write_mask <= dataIn;
                8'h01: status_reg_write <= dataIn;  
                8'h02: sample_clks_reg <= dataIn;
                8'h03: comp_settle_clks_reg <= dataIn;
                8'h04: adc_clken_div_loreg <= dataIn;
                8'h05: adc_clken_div_hireg <= dataIn;
            endcase
        end
    end

endmodule


 
