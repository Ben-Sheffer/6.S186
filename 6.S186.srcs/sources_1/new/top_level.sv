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


module top_level 
    (
        input clk_100mhz,
        input vauxp2 , vauxn2,
        input vauxp3 , vauxn3,
        input vauxp10, vauxn10,
        input [1:0] sw,
        output logic [1:0] jb
    );
    
    // XADC channel addresses
    wire [6:0] adc2  = 8'h12; // x-axis
    wire [6:0] adc3  = 8'h13; // y-axis
    wire [6:0] adc10 = 8'h1a; // force / piezo
    
    /** 
     * XADC data width 16-bit
     * Default address to channel 2
     * There is a 3 clock cycle delay between the changing the XADC channel
     *  and the data being ready on the bus
    **/
    logic signed [15:0] f, f_intermediate, f_hold;
    logic [15:0] adc_data, x_in, y_in;
    logic [6:0] adc_address = adc2; 
    logic [2:0] delay;
    logic eos_out, fresh_values;
    
    xadc_wiz_0 my_adc0(.dclk_in(clk_100mhz), 
                       .reset_in(0), 
                       .di_in(0), 
                       .den_in(1), 
                       .dwe_in(0), 
                       .vp_in(0), 
                       .vn_in(0),
                       .vauxp2(vauxp2)  , .vauxn2(vauxn2), 
                       .vauxn3(vauxn3)  , .vauxp3(vauxp3),
                       .vauxp10(vauxp10), .vauxn10(vauxn10),
                       .do_out(adc_data), 
                       .daddr_in(adc_address),                       
                       .eos_out(eos_out));
    
    /**
     * Control signals for the touchscreen
     * TODO: Investigate fall time of the touchscreen
    **/
    logic x_high = 1;
    logic [2:0] switch_axis = 0;
    assign jb[0] = x_high;
    assign jb[1] = !x_high;
    
    logic f_saxis_tvalid, f_saxis_tready, f_maxis_tvalid;
    logic signed [31:0] f_out;
    force_fixed_to_float force_convert(.aclk(clk_100mhz),
                                       .s_axis_a_tdata(f_intermediate), 
                                       .s_axis_a_tready(f_saxis_tready), 
                                       .s_axis_a_tvalid(f_saxis_tvalid),
                                       .m_axis_result_tdata(f_out), 
                                       .m_axis_result_tready(1), 
                                       .m_axis_result_tvalid(f_maxis_tvalid));
    
    /**
     * Discretizes digital signel into 50 states
    **/
    logic [6:0] x_out, y_out;
    discretize x(.clk(clk_100mhz), .control(jb[0]), .binary_in(x_in), .location_out(x_out));
    discretize y(.clk(clk_100mhz), .control(jb[1]), .binary_in(y_in), .location_out(y_out));
        
    ila_0 my_ila(.clk(clk_100mhz), 
                 .probe0(x_in), 
                 .probe1(y_in),
                 .probe2(adc_data), 
                 .probe3(f), 
                 .probe4(eos_out), 
                 .probe5(adc_address), 
                 .probe6(x_out), 
                 .probe7(y_out),
                 .probe8(jb[1:0]),
                 .probe9(f_out),
                 .probe10(f_intermediate));
    
    wire[15:0] center = 2**15;
    logic [9:0] threshold;
    logic [9:0] switch_out;
    vio_0 my_vio(.clk(clk_100mhz), 
                 .probe_out0(threshold));
    
    always_ff @(posedge clk_100mhz) begin
        if (eos_out) begin
            if (switch_axis >= 2) begin
                fresh_values <= 1;
                if (!x_high) begin
                    f_intermediate <= f_hold; 
                    f_saxis_tvalid <= 1;
                end
                x_high <= !x_high;
                switch_axis <= 0;
            end else begin
                switch_axis <= switch_axis + 1;
            end
        end else f_saxis_tvalid <= 0;
        
        if (fresh_values) begin
            case (adc_address)
                adc2: begin
                    adc_address <= adc3;
                    x_in <= adc_data;
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
        
        if (delay) begin
            case (delay)
                1: begin
                    delay <= delay + 1;
                end
                2: begin
                    y_in <= adc_data;
                    delay <= delay + 1;
                end
                3: begin
                    f <= adc_data;
                    delay <= delay + 1;
                end
                4: begin
                    f_hold <= (f < center - threshold | center + threshold < f) ? f - 2**15 : 16'sd0; // force threshold
                    delay <= 0;
                end
                default: begin
                    f_saxis_tvalid <= 0;
                end
            endcase
        end
    end
endmodule
