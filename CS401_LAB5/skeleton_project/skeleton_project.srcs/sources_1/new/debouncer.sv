`timescale 1ns / 1ps

module debouncer(
    input clk,
    input rst,
    input btn_in,
    output reg btn_out
);

    // 2-stage synchronizer
    reg s0, s1;

    // counter for fixed 10 ms debounce at 100 MHz
    reg [19:0] cnt;      // max 1,048,575
    reg stable;          // debounced level
    reg stable_d;        // previous debounced level

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s0       <= 0;
            s1       <= 0;
            cnt      <= 0;
            stable   <= 0;
            stable_d <= 0;
            btn_out  <= 0;
        end else begin
            // synchronize input
            s0 <= btn_in;
            s1 <= s0;

            // debounce counter
            if (s1 == stable) begin
                cnt <= 0;
            end else begin
                if (cnt == 20'd1_000_000) begin
                    stable <= s1;
                    cnt    <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            // generate 1-cycle pulse on rising edge of debounced signal
            stable_d <= stable;
            btn_out  <= stable & ~stable_d;
        end
    end

endmodule

