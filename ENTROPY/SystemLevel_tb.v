`timescale 1ns/1ps
module SystemLevel_tb;
    reg clk, rst_n, in_v, fault;
    reg [7:0] in_a, in_b;
    wire [15:0] out_f;

    TopGrid dut (.clk(clk), .rst_n(rst_n), .spike_in_data_a(in_a), .spike_in_data_b(in_b), .spike_in_valid(in_v), .fault_inject(fault), .spike_out_final(out_f));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("swarm_sim.vcd"); $dumpvars(0, SystemLevel_tb);
        clk=0; rst_n=0; in_v=0; in_a=0; in_b=0; fault=0;
        #20 rst_n=1;
        #10 in_v=1; in_a=8'd10; in_b=8'd5;
        #100 fault=1; // Trigger Reroute
        #100 $finish;
    end
endmodule