`timescale 1ns / 1ps
module top(
    input  logic clk, 
    input  logic reset,
    input  logic step_btn,
    input  logic start_btn, 
    input logic [15:0] SW,
    output logic led_done,
    output logic led_input_need,
    output logic [6:0]seg,
    output logic [7:0] SSEG_AN,
    output logic dp 
);
    logic step_pulse, start_pulse;
    // Debounce both buttons to 1-cycle pulses on clk
    debouncer db_step(clk, reset, step_btn, step_pulse);
    debouncer db_start(clk, reset, start_btn, start_pulse);
    
    // Only allow stepping in COMPUTE state
    logic step_en;
    assign step_en = (state == S_COMPUTE) ? step_pulse : 1'b0;
    
    //FSM states
    typedef enum logic [1:0] { S_START, S_COMPUTE, S_DONE } state_t;
    state_t state, state_next;
    
    // FSM: START -> COMPUTE -> DONE -> START ...
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= S_START;
        else       state <= state_next;
    end
    
    
    logic core_reset;
    assign core_reset = reset | (state != S_COMPUTE);
    
    (* MARK_DEBUG = "TRUE" *)  logic input_need, done;
    logic[31:0] sys_in_data, sys_out_data;
    mips_top core(clk,core_reset,done,input_need,step_en,sys_in_data,sys_out_data);
    
   
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            led_done <= 1'b0;
        end else begin
            if (done)
                led_done <= 1'b1;
        end
    end 
    
    assign led_input_need = input_need;
    
    logic [31:0] display_word, in_data;
    assign in_data = {{16{SW[15]}}, SW };
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            display_word <= 32'd0;
        end else begin
            if(step_en) begin
                display_word <= 32'd0;
            end else if(input_need) begin
                display_word <= in_data;
            end else if (sys_out_data != 32'd0) begin
                display_word <= sys_out_data;
            end
        end
    end
    
    assign sys_in_data = in_data;
    assign {in7,in6,in5,in4,in3,in2,in1,in0} = display_word;
    
    always_comb begin
        state_next = state;
        unique case (state)
            S_START:   if (start_pulse) state_next = S_COMPUTE;
            S_COMPUTE: if (done) state_next = S_DONE;
            S_DONE:    state_next = S_DONE;
        endcase
    end
    
    logic [3:0] in7,in6,in5,in4,in3, in2, in1, in0;
    display_controller disp(clk, in7, in6, in5, in4, in3, in2, in1, in0, seg, dp, SSEG_AN);
    

endmodule
