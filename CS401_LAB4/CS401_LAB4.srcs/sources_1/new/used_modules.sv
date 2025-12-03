`timescale 1ns / 1ps

// Written by David_Harris@hmc.edu
// Edited by ekinn@

// Top level system including MIPS and memories


module core  (
    input  logic clk_50, 
    input  logic reset,
    input  logic step_en          
);    

(* MARK_DEBUG = "TRUE" *) logic[31:0] writedata, dataadr; 
(* MARK_DEBUG = "TRUE" *) logic[31:0] pc, instr, readdata;           
(* MARK_DEBUG = "TRUE" *) logic       memwrite;


// "dont_touch" directives are for the synthesis tool, you can edit them freely

   // instantiate processor and memories  
   (* DONT_TOUCH = "TRUE" *) mips mips_i (
      .clk      (clk_50),
      .reset    (reset),
      .step_en  (step_en),
      .pc       (pc),
      .instr    (instr),
      .memwrite (memwrite),
      .aluout   (dataadr),
      .writedata(writedata),
      .readdata (readdata)
  );  
   (* DONT_TOUCH = "TRUE" *) imem imem_i (pc[7:2], instr);  
   
   (* DONT_TOUCH = "TRUE" *) dmem dmem_i (clk_50, reset, memwrite, dataadr, writedata, readdata);

endmodule



// External data memory used by MIPS single-cycle processor

module dmem (input  logic        clk,reset, we,
             input  logic[31:0]  a, wd,
             output logic[31:0]  rd);

   logic  [31:0] RAM[63:0];
  
   assign rd = RAM[a[7:2]];    // word-aligned  read (for lw)
   integer i;
   always_ff @(posedge clk or posedge reset) begin
     if(reset) begin
        $display("\n\n%t,resetting ram\n\n",$time);
        for(i=0;i<64;i=i+1) begin
            RAM[i] <= '0;
        end
     end else if (we) begin
       RAM[a[31:2]] <= wd;      // word-aligned write (for sw)
     end
   end
endmodule





// single-cycle MIPS processor, with controller and datapath

module mips (input  logic        clk, reset,
             input  logic        step_en, 
             output logic[31:0]  pc,
             input  logic[31:0]  instr,
             output logic        memwrite,
             output logic[31:0]  aluout, writedata,
             input  logic[31:0]  readdata);

  logic        memtoreg, pcsrc, zero, alusrc, regdst, regwrite, jump;
  logic [2:0]  alucontrol;
  logic        memwrite_int;
  
 
  (* DONT_TOUCH = "TRUE" *) controller c (
   instr[31:26], instr[5:0], zero, memtoreg, memwrite_int, pcsrc, alusrc, regdst, regwrite,jump, alucontrol );

                            datapath dp (
   clk, reset, step_en,memtoreg, pcsrc, alusrc,regdst, regwrite, jump, alucontrol, zero, pc,instr, aluout, writedata,readdata );


// Only allow memory writes when we are "stepping"
  assign memwrite = memwrite_int & step_en;
  
endmodule


module controller(input  logic[5:0] op, funct,
                  input  logic     zero,
                  output logic     memtoreg, memwrite,
                  output logic     pcsrc, alusrc,
                  output logic     regdst, regwrite,
                  output logic     jump,
                  output logic[2:0] alucontrol);

   logic [1:0] aluop;
   logic       branch;

   (* DONT_TOUCH = "TRUE" *) maindec md (op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, 
		 jump, aluop);

   (* DONT_TOUCH = "TRUE" *) aludec  ad (funct, aluop, alucontrol);

   assign pcsrc = branch & zero;

endmodule



// External instruction memory used by MIPS single-cycle
// processor. It models instruction memory as a stored-program 
// ROM, with address as input, and instruction as output


module imem ( input logic [5:0] addr, output logic [31:0] instr);

// imem is modeled as a lookup table, a stored-program byte-addressable ROM
	always_comb
	   case ({addr,2'b00})          // byte address
      8'h00: instr = 32'h20080005; // 0: 
      8'h04: instr = 32'h20090005; // 1: 
      8'h08: instr = 32'h11090002; // 2: 
      8'h0C: instr = 32'h01095020; // 3: 
      8'h10: instr = 32'h01095822; // 4: 
      8'h14: instr = 32'h20090003; // 5: 
      8'h18: instr = 32'h11090001; // 6: 
      8'h1C: instr = 32'h01096024; // 7: and  $12, $8, $9
      8'h20: instr = 32'h01096825; // 8: 
      8'h24: instr = 32'h0128702A; // 9: 
      8'h28: instr = 32'hAD2E0001; // 10: 
      8'h2C: instr = 32'h8D10FFFF; // 11: 
      8'h30: instr = 32'h120C0001; // 12: 
      8'h34: instr = 32'h2011006F; // 13: 
      8'h38: instr = 32'h0800000E; // 14:
      default: instr = 32'hXXXXXXXX;
    endcase
endmodule
module maindec (input logic[5:0] op, 
	              output logic memtoreg, memwrite, branch,
	              output logic alusrc, regdst, regwrite, jump,
	              output logic[1:0] aluop );
   logic [8:0] controls;

   assign {regwrite, regdst, alusrc, branch, memwrite,
                memtoreg,  aluop, jump} = controls;

  always_comb
    case(op)
      6'b000000: controls <= 9'b110000100; // R-type
      6'b100011: controls <= 9'b101001000; // LW
      6'b101011: controls <= 9'b001010000; // SW
      6'b000100: controls <= 9'b000100010; // BEQ
      6'b001000: controls <= 9'b101000000; // ADDI
      6'b000010: controls <= 9'b000000001; // J
      default:   controls <= 9'bxxxxxxxxx; // illegal op
    endcase
endmodule

module aludec (input    logic[5:0] funct,
               input    logic[1:0] aluop,
               output   logic[2:0] alucontrol);
  always_comb
    case(aluop)
      2'b00: alucontrol  = 3'b010;  // add  (for lw/sw/addi)
      2'b01: alucontrol  = 3'b110;  // sub   (for beq)
      default: case(funct)          // R-TYPE instructions
          6'b100000: alucontrol  = 3'b010; // ADD
          6'b100010: alucontrol  = 3'b110; // SUB
          6'b100100: alucontrol  = 3'b000; // AND
          6'b100101: alucontrol  = 3'b001; // OR
          6'b101010: alucontrol  = 3'b111; // SLT
          default:   alucontrol  = 3'bxxx; // ???
        endcase
    endcase
endmodule

module datapath (
    input  logic       clk, reset,
    input  logic       step_en,      // <--- our button
    input  logic       memtoreg, pcsrc, alusrc, regdst,
    input  logic       regwrite, jump, 
    input  logic[2:0]  alucontrol, 
    output logic       zero, 
    output logic[31:0] pc, 
    input  logic[31:0] instr,
    output logic[31:0] aluout, writedata, 
    input  logic[31:0] readdata
);

  logic [4:0]  writereg;
  logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
  logic [31:0] signimm, signimmsh, srca, srcb, result;
 
  // next PC logic
  flopenr #(32) pcreg (
      .clk   (clk),
      .reset (reset),
      .en    (step_en),      // only update PC on step
      .d     (pcnext),
      .q     (pc)
  );
  adder       pcadd1(pc, 32'b100, pcplus4);
  sl2         immsh(signimm, signimmsh);
  adder       pcadd2(pcplus4, signimmsh, pcbranch);
  mux2 #(32)  pcbrmux(pcplus4, pcbranch, pcsrc,
                      pcnextbr);
  mux2 #(32)  pcmux(pcnextbr, {pcplus4[31:28], 
                    instr[25:0], 2'b00}, jump, pcnext);

// register file logic
     regfile rf (
      .clk  (clk),
      .reset(reset),
      .we3  (regwrite & step_en),  // only write when stepping
      .ra1  (instr[25:21]),
      .ra2  (instr[20:16]),
      .wa3  (writereg),
      .wd3  (result),
      .rd1  (srca),
      .rd2  (writedata)
  );


   mux2 #(5)    wrmux (instr[20:16], instr[15:11], regdst, writereg);
   mux2 #(32)  resmux (aluout, readdata, memtoreg, result);
   signext         se (instr[15:0], signimm);

  // ALU logic
   mux2 #(32)  srcbmux (writedata, signimm, alusrc, srcb);
   alu         alu (srca, srcb, alucontrol, aluout, zero);

endmodule


module regfile (input    logic clk, reset, we3, 
                input    logic[4:0]  ra1, ra2, wa3, 
                input    logic[31:0] wd3, 
                output   logic[31:0] rd1, rd2);

(* MARK_DEBUG = "TRUE" *) logic [31:0] rf [31:0];

  // three ported register file: read two ports combinationally
  // write third port on rising edge of clock. Register0 hardwired to 0.
integer i;
  always_ff@(posedge clk or posedge reset) begin
     if(reset) begin
        for(i=0;i<32; i=i+1) begin
            rf[i] <= '0;
        end
     end else if (we3) begin 
//         $display("%t writing rf[%0d] = %h", $time, wa3, wd3);

         rf [wa3] <= wd3;
     end	
  end
  assign rd1 = (ra1 != 0) ? rf [ra1] : 0;
  assign rd2 = (ra2 != 0) ? rf [ra2] : 0;

endmodule


module alu(input  logic [31:0] a, b, 
           input  logic [2:0]  alucont, 
           output logic [31:0] result,
           output logic zero);
    
    always_comb
        case(alucont)
            3'b010: result = a + b;
            3'b110: result = a - b;
            3'b000: result = a & b;
            3'b001: result = a | b;
            3'b111: result = (a < b) ? 1 : 0;
            default: result = {32{1'bx}};
        endcase
    
    assign zero = (result == 0) ? 1'b1 : 1'b0;
endmodule


module adder (input  logic[31:0] a, b,
              output logic[31:0] y);
     
     assign y = a + b;
endmodule

module sl2 (input  logic[31:0] a,
            output logic[31:0] y);
     
     assign y = {a[29:0], 2'b00}; // shifts left by 2
endmodule

module signext (input  logic[15:0] a,
                output logic[31:0] y);
              
  assign y = {{16{a[15]}}, a};    // sign-extends 16-bit a
endmodule

// parameterized register
module flopr #(parameter WIDTH = 8)
              (input logic clk, reset, 
	       input logic[WIDTH-1:0] d, 
               output logic[WIDTH-1:0] q);

  always_ff@(posedge clk, posedge reset)
    if (reset) q <= 0; 
    else       q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)
(
    input  logic              clk, reset, en,
    input  logic[WIDTH-1:0]   d,
    output logic[WIDTH-1:0]   q
);
  always_ff @(posedge clk, posedge reset) begin
    if (reset) q <= '0;
    else if (en) q <= d;
  end
endmodule


// paramaterized 2-to-1 MUX
module mux2 #(parameter WIDTH = 8)
             (input  logic[WIDTH-1:0] d0, d1,  
              input  logic s, 
              output logic[WIDTH-1:0] y);
  
   assign y = s ? d1 : d0; 
endmodule

module heartbeat_0_5hz(
    input  logic clk_50,
    input  logic reset,
    output logic led_out
);

    localparam integer MAX = 50_000_000;  // 1 sec
    integer cnt;

    always_ff @(posedge clk_50 or posedge reset) begin
        if (reset) begin
            cnt     <= 0;
            led_out <= 0;
        end 
        else begin
            if (cnt >= MAX-1) begin
                cnt <= 0;
                led_out <= ~led_out;  // toggle every 1s
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule

module debouncer(
    input clk,
    input rst,
    input btn_in,
    output reg btn_out
);
    reg [4:0] shift_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 5'b0;
            btn_out <= 0;
        end else begin
            shift_reg <= {shift_reg[3:0], btn_in};
            btn_out <= shift_reg[3] & ~shift_reg[4]; // should be 1-cycle pulse on posedge
        end
    end
endmodule


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