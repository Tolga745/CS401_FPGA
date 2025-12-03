module top  (
    input  logic clk, 
    input  logic reset,
    input  logic step_btn,
    input  logic start_btn,
//    input  logic w_btn,
//    input  logic [15:0] SW, 
    output logic led0,
    output logic [6:0]seg,
    output logic [7:0] SSEG_AN,
    output logic dp
);    

//internal pulses from debouncers
(* MARK_DEBUG = "TRUE" *)logic step_pulse;
(* MARK_DEBUG = "TRUE" *)logic step_en;
(* MARK_DEBUG = "TRUE" *)logic start_pulse;


//FSM states
typedef enum logic [1:0] { S_START, S_COMPUTE, S_DONE } state_t;
(* MARK_DEBUG = "TRUE" *) state_t state, state_next;

logic clk_50;
logic locked; // for clock wizard, not important
logic sys_reset;

assign sys_reset = reset | ~locked;


// UNCOMMENT BELOW clk_wiz_100_to_50 MODULE ONLY FOR PART D
//AFTER DOING SO, PROVIDE clk_50 SIGNAL TO THE INSTANTIATED MODULES
clk_wiz_100_to_50 wiz
   (
    // Clock out ports
    .clk_out1(clk_50),     // output clk_out1
    // Status and control signals
    .reset(reset),         // input reset
    .locked(locked),       // output locked
    // Clock in ports
    .clk_in1(clk)          // input clk_in1
);

// Debounce both buttons to 1-cycle pulses on clk_50
debouncer db_step  (.clk(clk_50), .rst(sys_reset), .btn_in(step_btn),  .btn_out(step_pulse));
debouncer db_start (.clk(clk_50), .rst(sys_reset), .btn_in(start_btn), .btn_out(start_pulse));

// FSM: START -> COMPUTE -> DONE -> START ...
always_ff @(posedge clk_50 or posedge sys_reset) begin
    if (sys_reset) state <= S_START;
    else       state <= state_next;
end

always_comb begin
    state_next = state;
    unique case (state)
        S_START:   if (start_pulse) state_next = S_COMPUTE;
        S_COMPUTE: if (start_pulse) state_next = S_DONE;
        S_DONE:    if (start_pulse) state_next = S_START;
    endcase
end

// Only allow stepping in COMPUTE state
assign step_en = (state == S_COMPUTE) ? step_pulse : 1'b0;

// "dont_touch" directives are for the synthesis tool, you can edit them freely
/*!!!!!!!!!!!!!!!!!!!!!
IMPORTANT: the directive "(* DONT_TOUCH = "TRUE" *)" is for synthesis tool. Writing this
forbids any optimization to happen, in other words, what we write is what we will get at the synthesized
hardware. You can edit the core module as you wish, do not remove the "(* DONT_TOUCH = "TRUE" *)" directive
it should stay there. Same thing goes for any module that has the same directive before it.
*/

(* DONT_TOUCH = "TRUE" *) core core_instantiation (
    .clk_50      (clk_50),
    .reset    (sys_reset),
    .step_en  (step_en)
);  

// REST IS NOT IMPORTANT

logic [3:0] in7,in6,in5,in4,in3, in2, in1, in0;
logic [31:0] instr_on_ssd;
// don't edit clock here, should get the fast one
display_controller disp(

    .clk(clk_50),
    .in7(in7), .in6(in6), .in5(in5), .in4(in4),.in3(in3), .in2(in2), .in1(in1), .in0(in0),
    .seg(seg), 
    .dp(dp),
    .SSEG_AN(SSEG_AN)
    );

assign {in7,in6,in5,in4,in3, in2, in1, in0} = instr_on_ssd;
always @(*) begin
    instr_on_ssd = core_instantiation.instr;
end 

// For sanity checks, it should blink rightmost led with:  (ONLY WHEN CLK_WIZARD IS UNCOMMENTED)
// IF clk_wiz_100_to_50 IS ACTIVE => 1 second on, 1 second off
// ELSE => off
heartbeat_0_5hz hb (
    .clk_50 (clk_50),
    .reset  (sys_reset),
    .led_out(led0)
);

endmodule
