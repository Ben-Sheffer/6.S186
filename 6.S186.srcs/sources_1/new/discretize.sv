`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2020 11:45:51 AM
// Design Name: 
// Module Name: discretize
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module discretize
    (
        input control, clk, 
        input [15:0] binary_in,
        output [6:0] location_out
    );
    parameter resolution = 50;
    
    /**
     * Experimental results of touchscreen indicate 
     *  a min value of ~10,000 & max value of ~60,000
     *  on ADC channels
     * This corresponds to an offset of 10,000 & range of 50,000
    **/
    logic [15:0] offset;
    logic [15:0] range;
    vio_1 discretize_vio(.clk(clk), .probe_out0(offset), .probe_out1(range));
    
    logic [15:0] step_size = range / resolution;
    logic [6:0] hold;
    logic [6:0] i = 0;
    
    always_ff @(posedge clk) begin
        if (control) begin
            i <= 0;
        end else begin
            if (i*step_size + offset <= binary_in & binary_in < (i+1)*step_size + offset) begin
                hold <= i;
            end else if (i > 50) begin
                i = 0;
            end else begin
                i <= i + 1;
            end
        end
    end
    assign location_out = hold;
endmodule
