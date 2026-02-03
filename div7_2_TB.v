`timescale 1ns/1ps

module div_7_TB;

reg         clk   = 1'b0;
reg         rst   = 1'b1;
reg         start = 1'b0;
reg [15:0]  data  = 16'd0;

wire        valid;
wire        busy;
wire [3:0]  reminder;
wire [13:0] q;

div_7 dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .data(data),
    .valid(valid),
    .busy(busy),
    .reminder(reminder),
    .q(q)
);

integer i;
integer pass_cnt, fail_cnt;

integer sent_data;
integer exp_q, exp_r;

integer cyc;

// 100MHz clock (10ns period)
always #5 clk = ~clk;

initial begin
    pass_cnt = 0;
    fail_cnt = 0;

    // Reset for a few cycles
    repeat (5) @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    // Test 0..700
    for (i = 0; i <= 700; i = i + 1) begin

        // 1) Wait until DUT is idle
        while (busy == 1'b1) @(posedge clk);

        // 2) Put new data (stable before posedge that samples start)
        @(negedge clk);
        data = i[15:0];
        sent_data = i;

        // Pre-calc expected (nice for waveform)
        exp_q = sent_data / 7;
        exp_r = sent_data % 7;

        // 3) One-cycle start pulse
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        // 4) Wait for valid with a simple timeout
        cyc = 0;
        while (valid != 1'b1) begin
            @(posedge clk);
            cyc = cyc + 1;
            if (cyc > 300) begin
                $display("[%0t] TIMEOUT: valid never came for data=%0d", $time, sent_data);
                fail_cnt = fail_cnt + 1;
                $finish;
            end
        end

        // 5) Check result when valid is high
        if ((q !== exp_q[13:0]) || (reminder !== exp_r[3:0])) begin
            $display("[%0t] FAIL: data=%0d exp(q,r)=(%0d,%0d) got(q,r)=(%0d,%0d)",
                     $time, sent_data, exp_q, exp_r, q, reminder);
            fail_cnt = fail_cnt + 1;
        end else begin
            pass_cnt = pass_cnt + 1;
        end

        // 6) Optional: wait until DUT finishes DONE->IDLE cleanly
        // (Usually busy is already 0 at valid, but this is extra safe)
        while (busy == 1'b1) @(posedge clk);

        // 7) Make sure valid went back to 0 before next iteration (one pulse)
        while (valid == 1'b1) @(posedge clk);
    end

    $display("==========================================");
    $display("DONE. PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
    $display("==========================================");

    $finish;
end

endmodule
