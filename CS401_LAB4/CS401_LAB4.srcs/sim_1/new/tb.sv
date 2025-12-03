`timescale 1ns/1ps

module tb;

    logic clk;
    logic reset;
    logic step_btn;
    logic start_btn;
    
    logic led0;
    
    top dut (
        .clk      (clk),
        .reset    (reset),
        .step_btn (step_btn),
        .start_btn(start_btn),
        .led0(led0)
    );
    // Some ports are ommitted, we dont nned to see them on the output waveform. 

    // 100 MHz external clock (10 ns period) -> inside becomes 50 MHz via clk_wiz if its uncommented
    always #5 clk = ~clk;

    task pulse_start;
        begin
//            @(posedge clk); //or do #10, same as waiting 1 period
            start_btn = 1;
            repeat (5) @(posedge clk); // in reality, we keep it high for thousands of cycles, even with a short press
            start_btn = 0;
        end
    endtask

    task pulse_step;
        begin
            step_btn = 1;
            repeat (5) @(posedge clk);
            step_btn = 0;
        end
    endtask

    initial begin
        $display("=== tb started==="); //this is like print() in python

        reset = 1;
        clk = 0;
        step_btn=0;
        start_btn =0;
        repeat (5) @(posedge clk);
        reset = 0; // 5 cycles of reset
        
        wait (dut.locked == 1'b1);
        // Currently in S_START. Move to S_COMPUTE.
        pulse_start; // this is calling the task we defined above

        // Single-step ~25 instructions~ 
        repeat (20) begin
            pulse_step; 
            // let things settle
            repeat (1) @(posedge clk); //we can change 1 into a longer wait time befoer the other press
        end

        // Move to S_DONE (freeze CPU)
        pulse_start;

        $display("=== Simulation finished ===");
        #50;
        $finish;
    end

endmodule
