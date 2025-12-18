`timescale 1ns / 1ps

module mips_top (input logic clk,
                 input logic reset,
                 output logic done,
                 output logic input_need,
                 input logic input_given,
                 input logic[31:0] sys_in_data,
                 output logic[31:0] sys_out_data);
    
    (* MARK_DEBUG = "TRUE" *)  logic[31:0] instrF, PC;
    (* MARK_DEBUG = "TRUE" *)  logic PcSrcD, MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD;
    (* MARK_DEBUG = "TRUE" *)  logic [2:0]  alucontrol;
    (* MARK_DEBUG = "TRUE" *)  logic [31:0] instrD, ALUOutE, WriteDataE;
    (* MARK_DEBUG = "TRUE" *)  logic [1:0] ForwardAE, ForwardBE;
    (* MARK_DEBUG = "TRUE" *)  logic ForwardAD, ForwardBD;
    (* MARK_DEBUG = "TRUE" *)  logic SyscallD, SyscallInputD, DoneD;
    
    mips core(clk, reset, instrF, PC,PcSrcD, MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD, alucontrol, instrD, ALUOutE, WriteDataE, ForwardAE, ForwardBE, ForwardAD, ForwardBD, input_need, input_given, sys_in_data, sys_out_data, SyscallD, SyscallInputD, DoneD, done);
    
endmodule

module mips (input  logic clk, reset,
             output logic[31:0]  instrF,
             output logic[31:0] PC,
             output logic PcSrcD,
             output logic MemWriteD, MemToRegD, ALUSrcD, BranchD, RegDstD, RegWriteD,
             output logic [2:0]  alucontrol,
             output logic [31:0] instrD, 
             output logic [31:0] ALUOutE, WriteDataE,
             output logic [1:0] ForwardAE, ForwardBE,
             output logic ForwardAD, ForwardBD,
             output logic system_input_need,
             input logic system_input_given,
             input logic[31:0] sys_in_data,
             output logic[31:0] sys_out_data,
             output logic SyscallD, SyscallInputD, DoneD, done);

    
    (* DONT_TOUCH = "TRUE" *)controller CU(instrD[31:26], instrD[5:0], MemToRegD, MemWriteD, ALUSrcD, RegDstD, RegWriteD, alucontrol, BranchD, SyscallD, SyscallInputD, DoneD);
    
    datapath DP(clk, reset, alucontrol, RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD, BranchD, SyscallD, SyscallInputD, DoneD,
        instrF, instrD, 
        PC, PcSrcD,
        ALUOutE, WriteDataE, 
        ForwardAE, ForwardBE, ForwardAD, ForwardBD, 
        system_input_given, system_input_need, done,
        sys_in_data, sys_out_data);
        
endmodule

module imem ( input logic [5:0] addr, output logic [31:0] instr);

// imem is modeled as a lookup table, a stored-program byte-addressable ROM
	always_comb
	   case ({addr,2'b00})		   	// word-aligned fetch
//
// 	***************************************************************************
//	Here, you can paste your own test cases that you prepared for the part 1-e.
//  An example test program is given below.        
//	***************************************************************************
//
//		address		instruction
//		-------		-----------
        8'h00: instr = 32'h20100000; // 0:  addi $s0,$zero,0      # base = 0
        8'h04: instr = 32'h20080001; // 1:  addi $t0,$zero,1
        8'h08: instr = 32'h20090002; // 2:  addi $t1,$zero,2
        8'h0C: instr = 32'h200A0003; // 3:  addi $t2,$zero,3
        8'h10: instr = 32'h200B0004; // 4:  addi $t3,$zero,4
        8'h14: instr = 32'h20190003; // 5:  addi $t9,$zero,3
        8'h18: instr = 32'hAE080000; // 6:  sw   $t0,0($s0)        # mem[0]=1
        8'h1C: instr = 32'hAE090004; // 7:  sw   $t1,4($s0)        # mem[4]=2
        8'h20: instr = 32'hAE0A0008; // 8:  sw   $t2,8($s0)        # mem[8]=3
        8'h24: instr = 32'hAE0B000C; // 9:  sw   $t3,12($s0)       # mem[12]=4
   
        // ---- ALU -> ALU forwarding tests ----
        8'h28: instr = 32'h01096020; // 10: add  $t4,$t0,$t1       # EX/MEM->EX on A
        8'h2C: instr = 32'h018A6822; // 11: sub  $t5,$t4,$t2
        8'h30: instr = 32'h01097020; // 12: add  $t6,$t0,$t1
        8'h34: instr = 32'h014E7822; // 13: sub  $t7,$t2,$t6       # EX/MEM->EX on B
        8'h38: instr = 32'h0109C020; // 14: add  $t8,$t0,$t1       # producer t8
        8'h3C: instr = 32'h014B8820; // 15: add  $s1,$t2,$t3       # independent
        8'h40: instr = 32'h03099022; // 16: sub  $s2,$t8,$t1       # MEM/WB->EX on A
        8'h44: instr = 32'h01099820; // 17: add  $s3,$t0,$t1       # producer s3
        8'h48: instr = 32'h014BA020; // 18: add  $s4,$t2,$t3       # producer s4
        8'h4C: instr = 32'h0274A820; // 19: add  $s5,$s3,$s4       # both A/B forwarded
   
        // ---- ALU -> Branch, Store, Load ----
        8'h50: instr = 32'h20080005; // 20: addi $t0,$zero,5
        8'h54: instr = 32'h20090005; // 21: addi $t1,$zero,5
        8'h58: instr = 32'h01095022; // 22: sub  $t2,$t0,$t1
        8'h5C: instr = 32'h11400001; // 23: beq  $t2,$zero,BR_TAKEN1 (to PC=0x64)
        8'h60: instr = 32'h200B0011; // 24: addi $t3,$zero,0x11   # should be flushed
        8'h64: instr = 32'h0209B020; // 25: BR_TAKEN1: add $s6,$s0,$t1    # base addr
        8'h68: instr = 32'hAECA0000; // 26: sw   $t2,0($s6)        # addr depends on s6
        8'h6C: instr = 32'h01096020; // 27: add  $t4,$t0,$t1
        8'h70: instr = 32'hAE0C0004; // 28: sw   $t4,4($s0)        # store data depends on t4
        8'h74: instr = 32'h0209B820; // 29: add  $s7,$s0,$t1       # base for load
        8'h78: instr = 32'h8EED0000; // 30: lw   $t5,0($s7)        # load using s7 base
   
        // ---- Load-use hazards (need stall) ----
        8'h7C: instr = 32'h8E080000; // 31: lw   $t0,0($s0)        # LOAD_USE1
        8'h80: instr = 32'h010A4820; // 32: add  $t1,$t0,$t2       # lw->add (stall+fwd)
   
        8'h84: instr = 32'h8E0B0008; // 33: lw   $t3,8($s0)
        8'h88: instr = 32'h11790001; // 34: beq  $t3,$t9,BR_TAKEN2 (to PC=0x90)
        8'h8C: instr = 32'h200C0022; // 35: addi $t4,$zero,0x22    # should be flushed
        8'h90: instr = 32'h8E0D0004; // 36: BR_TAKEN2: lw $t5,4($s0)
        8'h94: instr = 32'hAE0D0014; // 37: sw   $t5,20($s0)       # lw->sw data
   
        8'h98: instr = 32'h8E11000C; // 38: lw   $s1,12($s0)
        8'h9C: instr = 32'hAE280000; // 39: sw   $t0,0($s1)        # lw->sw addr
   
        8'hA0: instr = 32'h8E0E0000; // 40: lw   $t6,0($s0)
        8'hA4: instr = 32'h00000020; // 41: add  $zero,$zero,$zero # nop
        8'hA8: instr = 32'h01CE7820; // 42: add  $t7,$t6,$t6       # lw; nop; add (no stall)
   
        // ---- Store -> Load (memory RAW) ----
        8'hAC: instr = 32'h2018004D; // 43: addi $t8,$zero,77
        8'hB0: instr = 32'hAE180018; // 44: sw   $t8,24($s0)
        8'hB4: instr = 32'h8E190018; // 45: lw   $t9,24($s0)       # store->load same addr
   
        8'hB8: instr = 32'h20120058; // 46: addi $s2,$zero,88
        8'hBC: instr = 32'hAE12001C; // 47: sw   $s2,28($s0)
        8'hC0: instr = 32'hAE090020; // 48: sw   $t1,32($s0)
        8'hC4: instr = 32'h8E13001C; // 49: lw   $s3,28($s0)       # later store->load        
        
        8'hC8: instr = 32'hE8000000; // SYSCALL TERMINATE    
        
       default: instr = 32'h00000000;	// unknown address
	   endcase 
endmodule

// External data memory used by MIPS single-cycle processor
module dmem (input  logic        clk, we,
             input  logic[31:0]  a, wd,
             output logic[31:0]  rd);

   logic  [31:0] RAM[63:0];
   
   assign rd = RAM[a[7:2]];    // word-aligned  read (for lw)
   
   always_ff @(posedge clk)  
     if (we)
       RAM[a[7:2]] <= wd;      // word-aligned write (for sw)
  
endmodule

module datapath (input  logic clk, reset,
                input  logic[2:0]  ALUControlD,
                input logic RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD, BranchD, SyscallD, SyscallInputD, DoneD,
                 output logic [31:0] instrF,		
                 output logic [31:0] instrD, PC,
                output logic PcSrcD,                 
                output logic [31:0] ALUOutE, WriteDataE,
                output logic [1:0] ForwardAE, ForwardBE,
                 output logic ForwardAD, ForwardBD,
                 input logic system_input_given,
                 output logic system_input_need, done,
                 input logic[31:0] sys_in_data,
                 output logic[31:0] sys_out_data); // Add or remove input-outputs if necessary

	// ********************************************************************
	// Here, define the wires that are needed inside this pipelined datapath module
	// ********************************************************************
  
  	// Fetch Stage Signals
    logic [31:0] PCF, PcPlus4F, PcSrcA, PcSrcB;
    
    // Decode Stage Signals
    logic [31:0] PcBranchD, PcPlus4D; 
    logic [31:0] SignImmD, ShiftedImmD;
    logic [31:0] RD1, RD2;
    
    // Execute Stage Signals
    logic [31:0] RsDataE, RtDataE, SignImmE;
    logic [4:0]  RsE, RtE, RdE, WriteRegE;
    logic RegWriteE, MemToRegE, MemWriteE, ALUSrcE, RegDstE;
    logic [2:0] ALUControlE;
    logic SyscallE, SyscallInputE, DoneE;
    logic [31:0] SrcAE, SrcBE, WriteDataE_fwd; // Forwarded values
    logic [31:0] ALUResultE, FinalALUOutE;     // ALU results
    logic [31:0] SyscallDataE;                 // Data from Syscall Handler
    
    // Memory Stage Signals
    logic RegWriteM, MemToRegM, MemWriteM;
    logic [31:0] ALUOutM, WriteDataM, ReadDataM;
    logic [4:0]  WriteRegM;
    
    // Writeback Stage Signals
    logic RegWriteW, MemToRegW;
    logic [31:0] ALUOutW, ReadDataW, ResultW;
    logic [4:0]  WriteRegW;
    
    /////////////////////////////////////////////////// Fetch stage //////////////////////////////////////////////////////////////////////////
    (* MARK_DEBUG = "TRUE" *) logic StallF, StallD, StallE, FlushE; 
  	// Replace with PipeWtoF
    PipeWtoF pcreg(
        .PC(PC), 
        .EN(~StallF),   
        .clk(clk), 
        .reset(reset), 
        .PCF(PCF)
    );

    // PC Mux Logic
    assign PcPlus4F = PCF + 4;
    assign PcSrcB = PcBranchD;
    assign PcSrcA = PcPlus4F;
    mux2 #(32) pc_mux(PcSrcA, PcSrcB, PcSrcD, PC);

    // Instruction Memory
    imem im1(PCF[7:2], instrF);

    // Pipeline Register: Fetch -> Decode
    // Enable = ~StallD, Clear = PcSrcD (Flush on branch taken)
    PipeFtoD pfd(instrF, PcPlus4F, ~StallD, PcSrcD, clk, reset, instrD, PcPlus4D);
   
  	/////////////////////////////////////////////////// Decode stage //////////////////////////////////////////////////////////////////////////
  	// Register File
    regfile rf(clk, reset, RegWriteW, instrD[25:21], instrD[20:16], WriteRegW, ResultW, RD1, RD2);
    
    // Sign Extension & Branch Logic
    signext se(instrD[15:0], SignImmD);
    sl2 shiftimm(SignImmD, ShiftedImmD);
    adder branchadd(PcPlus4D, ShiftedImmD, PcBranchD); 
    
    // Branch Decision
    assign PcSrcD = BranchD & (RD1 == RD2);

    // Pipeline Register: Decode -> Execute
    PipeDtoE pde(
        ~StallE, // Enable
        RD1, RD2, SignImmD,
        instrD[25:21], instrD[20:16], instrD[15:11],
        RegWriteD, MemToRegD, MemWriteD, ALUSrcD, RegDstD,
        ALUControlD,
        SyscallD, SyscallInputD, DoneD,
        FlushE, clk, reset,
        RsDataE, RtDataE, SignImmE,
        RsE, RtE, RdE, 
        RegWriteE, MemToRegE, MemWriteE, ALUSrcE, RegDstE,
        ALUControlE,
        SyscallE, SyscallInputE, DoneE
    );
  
  	// Instantiate PipeDtoE here
  	
  	/////////////////////////////////////////////////// Execute stage //////////////////////////////////////////////////////////////////////////
    // Forwarding Multiplexers (3-way)
    // Selects: 00=RegFile, 01=Writeback Stage, 10=Memory Stage
    
    // Forwarding Mux for Source A
    always_comb begin
        case (ForwardAE)
            2'b00: SrcAE = RsDataE;
            2'b01: SrcAE = ResultW;
            2'b10: SrcAE = ALUOutM;
            default: SrcAE = RsDataE;
        endcase
    end

    // Forwarding Mux for WriteData (Source B before Immediate Mux)
    always_comb begin
        case (ForwardBE)
            2'b00: WriteDataE_fwd = RtDataE;
            2'b01: WriteDataE_fwd = ResultW;
            2'b10: WriteDataE_fwd = ALUOutM;
            default: WriteDataE_fwd = RtDataE;
        endcase
    end

    // ALU Source B Mux (Immediate Selection)
    mux2 #(32) srcBMux(WriteDataE_fwd, SignImmE, ALUSrcE, SrcBE);

    // ALU
    alu alu(SrcAE, SrcBE, ALUControlE, ALUResultE);
    
    // Write Register Mux (Rt vs Rd)
    mux2 #(5) wrMux(RtE, RdE, RegDstE, WriteRegE);

    // Custom Syscall Handler
    // SrcAE contains the value of $rs (for Output syscall)
    // SyscallDataE receives value for $rt (for Input syscall)
    syscall_handler sh(SyscallE, SyscallInputE, system_input_given, 
                       SrcAE, sys_in_data, system_input_need, 
                       SyscallDataE, sys_out_data);
                       
    assign done = DoneE; // Connect Done signal to output

    // Select Final Result (ALU Result vs Syscall Input)
    assign FinalALUOutE = (SyscallInputE) ? SyscallDataE : ALUResultE;
    
    // Assign WriteDataE output 
    assign WriteDataE = WriteDataE_fwd;
    assign ALUOutE = FinalALUOutE;

    // Pipeline Register: Execute -> Memory
    PipeEtoM pem(clk, reset,
                 RegWriteE, MemToRegE, MemWriteE,
                 FinalALUOutE, WriteDataE_fwd, 
                 WriteRegE,
                 RegWriteM, MemToRegM, MemWriteM,
                 ALUOutM, WriteDataM,
                 WriteRegM);

  	/////////////////////////////////////////////////// Memory stage //////////////////////////////////////////////////////////////////////////
  	// Data Memory
    dmem DM(clk, MemWriteM, ALUOutM, WriteDataM, ReadDataM);

    // Pipeline Register: Memory -> Writeback
    PipeMtoW pmw(clk, reset,
                 RegWriteM, MemToRegM,
                 ALUOutM, ReadDataM,
                 WriteRegM,
                 RegWriteW, MemToRegW,
                 ALUOutW, ReadDataW,
                 WriteRegW);
  
  	/////////////////////////////////////////////////// Writeback stage //////////////////////////////////////////////////////////////////////////
  	// Writeback Mux (ALU Result vs Memory Data)
    mux2 #(32) wbmux(ALUOutW, ReadDataW, MemToRegW, ResultW);
  	
  	HazardUnit hu(
        RegWriteW, BranchD,            
        WriteRegW, WriteRegE,
        RegWriteM, MemToRegM,
        WriteRegM,
        RegWriteE, MemToRegE,
        RsE, RtE,
        instrD[25:21], instrD[20:16],
        system_input_need,
        ForwardAE, ForwardBE,
        FlushE, StallE, StallD, StallF, ForwardAD, ForwardBD
    );
  	
  	
endmodule

module syscall_handler(input syscall, input_need, input_given,
                       input logic [31:0] a0, sys_in_data,
                       output logic system_input_need,
                       output logic [31:0] syscall_handler_out, sys_out_data
                       );
    always_comb begin
        if(syscall) begin
            sys_out_data = a0;
            syscall_handler_out = sys_in_data;    
        end else begin
            sys_out_data = 0;
            syscall_handler_out = 0;
        end 
        
        if(input_need & ~input_given) begin
            system_input_need = 1'b1;
        end else begin
            system_input_need = 1'b0;
        end
    end
endmodule

module PipeFtoD(input logic[31:0] instr, PcPlus4F,
                input logic EN, clear, clk, reset,  
                output logic[31:0] instrD, PcPlus4D);
    
    always_ff @(posedge clk, posedge reset) begin
        if (reset || clear) begin
            instrD   <= 0;
            PcPlus4D <= 0;
        end
        else if (EN) begin
            instrD   <= instr;
            PcPlus4D <= PcPlus4F;
        end
    end

endmodule

// The pipe between Writeback (W) and Fetch (F) is given as follows.

module PipeWtoF(input logic[31:0] PC,
                input logic EN, clk, reset,		// ~StallF will be connected as this EN
                output logic[31:0] PCF);

                always_ff @(posedge clk, posedge reset)
                    if(reset)
                        PCF <= 0;
                    else if(EN)
                        PCF <= PC;
endmodule

module PipeDtoE(input EN,
                input logic[31:0] RD1, RD2, SignImmD,
                input logic[4:0] RsD, RtD, RdD,
                input logic RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, RegDstD,
                input logic[2:0] ALUControlD,
                input logic SyscallD, SyscallInputD, DoneD,
                input logic clear, clk, reset,
                output logic[31:0] RsData, RtData, SignImmE,
                output logic[4:0] RsE, RtE, RdE, 
                output logic RegWriteE, MemtoRegE, MemWriteE, ALUSrcE, RegDstE,
                output logic[2:0] ALUControlE,
                output logic SyscallE, SyscallInputE, DoneE);

        always_ff @(posedge clk, posedge reset)
          if(reset || clear)
                begin
                // Control signals                
                MemtoRegE <= 0;
                RegWriteE <= 0;
                MemWriteE <= 0;
                ALUControlE <= 0;
                ALUSrcE <= 0;
                RegDstE <= 0;
                SyscallE <= 0;
                SyscallInputE <= 0;
                DoneE <= 0;
                
                // Data
                RsData <= 0;
                RtData <= 0;
                RsE <= 0;
                RtE <= 0;
                RdE <= 0;
                SignImmE <= 0;
                end
            else if(EN)
                begin
                // Control signals
                RegWriteE <= RegWriteD;
                MemtoRegE <= MemtoRegD;
                MemWriteE <= MemWriteD;
                ALUControlE <= ALUControlD;
                ALUSrcE <= ALUSrcD;
                RegDstE <= RegDstD;
                SyscallE <= SyscallD;
                SyscallInputE <= SyscallInputD;
                DoneE <= DoneD;
                
                // Data
                RsData <= RD1;
                RtData <= RD2;
                RsE <= RsD;
                RtE <= RtD;
                RdE <= RdD;
                SignImmE <= SignImmD;
                end
            

endmodule

module PipeEtoM(input logic clk, reset,
                input logic RegWriteE, MemtoRegE, MemWriteE,
                input logic [31:0] ALUOutE, WriteDataE,
                input logic [4:0] WriteRegE,
                output logic RegWriteM, MemtoRegM, MemWriteM,
                output logic [31:0] ALUOutM, WriteDataM,
                output logic [4:0] WriteRegM);
                
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            RegWriteM <= 0; MemtoRegM <= 0; MemWriteM <= 0;
            ALUOutM <= 0; WriteDataM <= 0; WriteRegM <= 0;
        end else begin
            RegWriteM <= RegWriteE; MemtoRegM <= MemtoRegE; MemWriteM <= MemWriteE;
            ALUOutM <= ALUOutE; WriteDataM <= WriteDataE; WriteRegM <= WriteRegE;
        end
    end

endmodule

module PipeMtoW(input logic clk, reset,
                input logic RegWriteM, MemtoRegM,
                input logic [31:0] ALUOutM, ReadDataM,
                input logic [4:0] WriteRegM,
                output logic RegWriteW, MemtoRegW,
                output logic [31:0] ALUOutW, ReadDataW,
                output logic [4:0] WriteRegW);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            RegWriteW <= 0; MemtoRegW <= 0;
            ALUOutW <= 0; ReadDataW <= 0; WriteRegW <= 0;
        end else begin
            RegWriteW <= RegWriteM; MemtoRegW <= MemtoRegM;
            ALUOutW <= ALUOutM; ReadDataW <= ReadDataM; WriteRegW <= WriteRegM;
        end
    end
		
endmodule

module HazardUnit( input logic RegWriteW, BranchD,            
                input logic [4:0] WriteRegW, WriteRegE,
                input logic RegWriteM, MemtoRegM,
                input logic [4:0] WriteRegM,
                input logic RegWriteE, MemtoRegE,
                input logic [4:0] rsE, rtE,
                input logic [4:0] rsD, rtD,
                input logic input_need,
                output logic [1:0] ForwardAE, ForwardBE,
                output logic FlushE, StallE, StallD, StallF, ForwardAD, ForwardBD
); // Add or remove input-outputs if necessary

    logic lwstall, lwstall_prev;

    always_comb begin
        // --- Forwarding Logic (Execute Stage) ---
        // Forward A: 10 from Memory (priority), 01 from WB
        if (RegWriteM && (WriteRegM != 0) && (WriteRegM == rsE))
            ForwardAE = 2'b10;
        else if (RegWriteW && (WriteRegW != 0) && (WriteRegW == rsE))
            ForwardAE = 2'b01;
        else
            ForwardAE = 2'b00;

        // Forward B: 10 from Memory (priority), 01 from WB
        if (RegWriteM && (WriteRegM != 0) && (WriteRegM == rtE))
            ForwardBE = 2'b10;
        else if (RegWriteW && (WriteRegW != 0) && (WriteRegW == rtE))
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;

        // --- Stall Logic ---
        
        // Load-Use Hazard Detection
        // Occurs if instruction in Decode needs data from a Load in Execute
        lwstall = MemtoRegE && RegWriteE &&  
  ((rtE == rsD) || (rtE == rtD)) &&
  (rtE != 0);

        // Stall Signals
        // We stall F and D if there is a Load-Use hazard OR if waiting for Input
        StallF = lwstall || input_need;
        StallD = lwstall || input_need;
        StallE = input_need; // Only freeze Execute stage for input wait
        

        // Flush Execute
        // If we stall Decode for Load-Use, we must insert a bubble (Flush) into Execute.
        // But if it's an Input wait, we don't flush, we just freeze.
        FlushE = lwstall; 
        
        // Decode Forwarding (Optional, checks if Branch operand depends on MEM result)
        ForwardAD = (RegWriteM && (WriteRegM != 0) && (WriteRegM == rsD));
        ForwardBD = (RegWriteM && (WriteRegM != 0) && (WriteRegM == rtD));
    end

endmodule


module controller(input  logic[5:0] op, funct,
                  output logic     memtoreg, memwrite,
                  output logic     alusrc,
                  output logic     regdst, regwrite,
                  output logic[2:0] alucontrol,
                  output logic branch,
                  output logic syscall, syscall_input, done);
    
    logic [1:0] aluop;
    maindec md (op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, aluop, syscall, syscall_input, done);
    aludec ad (funct, aluop, alucontrol);
    
    

endmodule

module maindec (input logic[5:0] op, 
	              output logic memtoreg, memwrite, branch,
	              output logic alusrc, regdst, regwrite,
	              output logic[1:0] aluop,
	              output logic syscall, syscall_input, done);
  logic [10:0] controls;

   assign {regwrite, regdst, alusrc, branch, memwrite,
                memtoreg, aluop, syscall, syscall_input, done} = controls;

  always_comb
    case(op)
      6'b000000: controls <= 11'b11000010000; // R-type
      6'b100011: controls <= 11'b10100100000; // LW
      6'b101011: controls <= 11'b00101000000; // SW
      6'b000100: controls <= 11'b00010001000; // BEQ
      6'b001000: controls <= 11'b10100000000; // ADDI
      6'b111000: controls <= 11'b10000000110; // SYSCALL INPUT
      6'b111001: controls <= 11'b00000000100; // SYSCALL OUTPUT
      6'b111010: controls <= 11'b00000000101; // SYSCALL TERMINATE
      default:   controls <= 11'bxxxxxxxxxxx; // illegal op
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

module regfile (input    logic clk, reset, we3, 
                input    logic[4:0]  ra1, ra2, wa3, 
                input    logic[31:0] wd3, 
                output   logic[31:0] rd1, rd2);

  logic [31:0] rf [31:0];

  always_ff @(posedge clk)
     if (reset) begin
        for (int i=0; i<29; i++) rf[i] = 32'b0;
        rf[29]= 32'bX;
        for (int i=30; i<32; i++) rf[i] = 32'b0;
     end else if (we3  && (wa3 != 5'd0)) begin
        rf[wa3] <= wd3;
     end
  
  //Negedge Behavior 
  assign rd1 = (ra1 != 0) ? ((ra1 == wa3 && we3) ? wd3 : rf[ra1]) : 0;
  assign rd2 = (ra2 != 0) ? ((ra2 == wa3 && we3) ? wd3 : rf[ra2]) : 0;
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

// paramaterized 2-to-1 MUX
module mux2 #(parameter WIDTH = 8)
             (input  logic[WIDTH-1:0] d0, d1,  
              input  logic s, 
              output logic[WIDTH-1:0] y);
  
   assign y = s ? d1 : d0; 
endmodule

// paramaterized 4-to-1 MUX
module mux4 #(parameter WIDTH = 8)
             (input  logic[WIDTH-1:0] d0, d1, d2, d3,
              input  logic[1:0] s, 
              output logic[WIDTH-1:0] y);
  
   assign y = s[1] ? ( s[0] ? d3 : d2 ) : (s[0] ? d1 : d0); 
endmodule