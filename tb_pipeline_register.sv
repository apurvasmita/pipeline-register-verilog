`timescale 1ns/1ps

module tb_pipeline_register;

    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    logic clk;
    logic rst_n;
    logic in_valid;
    logic in_ready;
    logic [DATA_WIDTH-1:0] in_data;
    logic out_valid;
    logic out_ready;
    logic [DATA_WIDTH-1:0] out_data;

    pipeline_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data)
    );

    // Clock
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        in_valid = 0;
        in_data = 0;
        out_ready = 0;

        #20;
        rst_n = 1;

        // Basic transfer
        @(posedge clk);
        in_valid = 1;
        in_data  = 32'hDEADBEEF;
        out_ready = 1;

        @(posedge clk);
        in_valid = 0;

        repeat (3) @(posedge clk);

        // Backpressure
        in_valid = 1;
        in_data  = 32'hCAFEBABE;
        out_ready = 0;

        repeat (3) @(posedge clk);
        out_ready = 1;

        repeat (5) @(posedge clk);

        $display("Simulation completed");
        $finish;
    end

endmodule
