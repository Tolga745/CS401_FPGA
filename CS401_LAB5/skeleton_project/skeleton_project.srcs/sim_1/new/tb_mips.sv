`timescale 1ns / 1ps

module tb_mips;

    // ---------------------------------------------------------
    // 1. Signals & Variables
    // ---------------------------------------------------------
    // DUT I/O
    logic clk;
    logic reset;
    logic done;
    logic input_need;
    logic input_given;
    logic [31:0] sys_in_data;
    logic [31:0] sys_out_data;

    // Test Configuration
    // Change this value to test different inputs (e.g., 5, 7, 10)
    logic [31:0] fib_input = 32'd8; 

    // ---------------------------------------------------------
    // 2. DUT Instantiation
    // ---------------------------------------------------------
    mips_top dut(
        .clk          (clk),
        .reset        (reset),
        .done         (done),
        .input_need   (input_need),
        .input_given  (input_given),
        .sys_in_data  (sys_in_data),
        .sys_out_data (sys_out_data)
    );

    // ---------------------------------------------------------
    // 3. Clock Generation
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns Clock Period
    end

    // ---------------------------------------------------------
    // 4. Input Handshake Logic (The "Driver")
    // ---------------------------------------------------------
    initial begin
        // Initialize signals
        sys_in_data = 0;
        input_given = 0;

        // Wait for reset to finish
        wait(reset == 0);

        // Infinite loop to listen for input requests
        forever begin
            @(posedge clk);
            if (input_need) begin
                $display("[TB] Processor requested input. Providing n = %0d...", fib_input);
                
                // 1. Setup Data
                sys_in_data <= fib_input;
                
                // 2. Assert Handshake Signal
                input_given <= 1'b1;
                
                // 3. Wait exactly one cycle for the processor to catch it
                @(posedge clk);
                
                // 4. De-assert signals
                input_given <= 1'b0;
                sys_in_data <= 32'b0; // Clean up bus (optional)
            end
        end
    end

    // ---------------------------------------------------------
    // 5. Output Monitor (The "Scoreboard")
    // ---------------------------------------------------------
    always @(posedge clk) begin
        // Print whenever valid data appears on the output line
        if (sys_out_data !== 32'b0) begin
            $display("[TB] >>> OUTPUT DETECTED: %0d (Hex: %h) <<<", sys_out_data, sys_out_data);
        end
    end

    // ---------------------------------------------------------
    // 6. Main Simulation Control
    // ---------------------------------------------------------
    initial begin
        // A. Reset Sequence
        reset = 1;
        repeat (5) @(posedge clk); // Hold reset for 5 cycles
        reset = 0;
        
        $display("=== Simulation Started ===");
        $display("Calculating Recursive Fibonacci for input: %0d", fib_input);

        // B. Wait for Completion
        // The 'done' signal comes from the syscall_terminate instruction
        wait(done);
        
        // C. Wrap up
        repeat (2) @(posedge clk); // Wait a moment for final signals to settle
        $display("=== Simulation Finished Successfully ===");
        $finish;
    end

endmodule