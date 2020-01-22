`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2020 07:43:58 PM
// Design Name: 
// Module Name: top_level
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


module top_level(
        input clk_100mhz,
        input vauxp2 , vauxn2,
        input vauxp3 , vauxn3,
        input vauxp10, vauxn10,
        input [1:0] sw,
        output logic [1:0] jb
    );
    
    wire [6:0] adc2  = 8'h12;
    wire [6:0] adc3  = 8'h13;
    wire [6:0] adc10 = 8'h1a;
    
    logic [11:0] adc_data, x, y, f;
    logic [6:0] adc_address = adc2;
    logic [1:0] delay;
    logic fresh_values, eos_out;
    
    xadc_wiz_0 my_adc0(.dclk_in(clk_100mhz), .di_in(0), .den_in(1), .dwe_in(0), .reset_in(0), .vp_in(0), .vn_in(0),
                       .vauxp2(vauxp2)  , .vauxn2(vauxn2), 
                       .vauxn3(vauxn3)  , .vauxp3(vauxp3),
                       .vauxp10(vauxp10), .vauxn10(vauxn10),
                       .do_out(adc_data), .daddr_in(adc_address),                       
                       .eos_out(eos_out));
    
    always_ff @(posedge clk_100mhz) begin
        if (eos_out) fresh_values <= 1;
        
        if (fresh_values) begin
            case (adc_address)
                adc2: begin
                    adc_address <= adc3;
                    x <= adc_data;
                end
                
                adc3: begin
                    adc_address <= adc10;
                end
                
                adc10: begin
                    adc_address <= adc2;
                    fresh_values <= 0;
                    delay <= 1;
                end 
                
                default: begin
                    adc_address <= adc2;
                    fresh_values <= 0;
                end
            endcase
        end
        
        case (delay)
            1: begin
                y <= adc_address;
                delay <= delay + 1;
            end
            2: begin
                f <= adc_address;
                delay <= 0;
            end
        endcase
    end
endmodule
