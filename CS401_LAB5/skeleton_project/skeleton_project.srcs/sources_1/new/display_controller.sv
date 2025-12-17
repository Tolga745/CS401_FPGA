`timescale 1ns / 1ps

module display_controller(

    input clk,
    input [3:0] in7,in6,in5,in4,in3, in2, in1, in0,
    output [6:0]seg, 
    output dp,
    output [7:0] SSEG_AN
);

    localparam N = 18;
    
    logic [N-1:0] count = {N{1'b0}};
    always@ (posedge clk)
        count <= count + 1;
    
    logic [4:0]digit_val;
    
    logic [7:0]digit_en;
    always@ (*)begin
        digit_en = 8'b11111111;
        digit_val = in0;
        
        case(count[N-1:N-3])
            3'b000 :begin	//select first 7Seg.       
                digit_val = {1'b0, in0};
                digit_en = 8'b1111_1110;
            end
            
            3'b001:begin	//select second 7Seg.
                digit_val = {1'b0, in1};
                digit_en = 8'b1111_1101;
            end
            
            3'b010:begin	//select third 7Seg.
                digit_val = {1'b0, in2};
                digit_en = 8'b1111_1011;
            end
            
            3'b011:begin	//select forth 7Seg. 
                digit_val = {1'b0, in3};
                digit_en = 8'b1111_0111;
            end
            
            3'b100 :begin	//select 5th 7Seg.       
                digit_val = {1'b0, in4};
                digit_en = 8'b1110_1111;
            end
            
            3'b101:begin	//select 6th 7Seg.
                digit_val = {1'b0, in5};
                digit_en = 8'b1101_1111;
            end
            
            3'b110:begin	//select 7th 7Seg.
                digit_val = {1'b0, in6};
                digit_en = 8'b1011_1111;
            end
            
            3'b111:begin	//select 8th 7Seg. 
                digit_val = {1'b0, in7};
                digit_en = 8'b0111_1111;
            end
        endcase
        end
    
    //Convert digit number to LED vector. LEDs are active low.
    
    logic [6:0] sseg_LEDs;
    always @(*)begin
        sseg_LEDs = 7'b1111111; //default
        case( digit_val)
            5'd0 : sseg_LEDs = 7'b1000000; //to display 0
            5'd1 : sseg_LEDs = 7'b1111001; //to display 1
            5'd2 : sseg_LEDs = 7'b0100100; //to display 2
            5'd3 : sseg_LEDs = 7'b0110000; //to display 3
            5'd4 : sseg_LEDs = 7'b0011001; //to display 4
            5'd5 : sseg_LEDs = 7'b0010010; //to display 5
            5'd6 : sseg_LEDs = 7'b0000010; //to display 6
            5'd7 : sseg_LEDs = 7'b1111000; //to display 7
            5'd8 : sseg_LEDs = 7'b0000000; //to display 8
            5'd9 : sseg_LEDs = 7'b0010000; //to display 9
            5'd10: sseg_LEDs = 7'b0001000; //to display a
            5'd11: sseg_LEDs = 7'b0000011; //to display b
            5'd12: sseg_LEDs = 7'b1000110; //to display c
            5'd13: sseg_LEDs = 7'b0100001; //to display d
            5'd14: sseg_LEDs = 7'b0000110; //to display e
            5'd15: sseg_LEDs = 7'b0001110; //to display f
            5'd16: sseg_LEDs = 7'b0110111; //to display "="
            default : sseg_LEDs = 7'b0111111; //dash 
        endcase
    end
    
    assign SSEG_AN = digit_en;
    assign seg = sseg_LEDs;
    assign dp = 1'b1; //turn dp off
    
endmodule
