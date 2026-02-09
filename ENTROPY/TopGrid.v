module TopGrid (
    clk,
    rst_n,
    spike_in_data_a,
    spike_in_data_b,
    spike_in_valid,
    fault_inject,
    spike_out_final
);

    input         clk;
    input         rst_n;
    input  [7:0]  spike_in_data_a;
    input  [7:0]  spike_in_data_b;
    input         spike_in_valid;
    input         fault_inject;
    output [15:0] spike_out_final;

    wire [7:0]  node00_stress;
    wire        backpressure;
    wire [15:0] n00_out, n01_out;

    assign backpressure = (node00_stress > 8'd200) || fault_inject;

    wire [7:0] n00_a = (!backpressure && spike_in_valid) ? spike_in_data_a : 8'd0;
    wire [7:0] n01_a = (backpressure && spike_in_valid)  ? spike_in_data_a : 8'd0;

    SwarmNode n00 (.clk(clk), .rst_n(rst_n), .spike_in(spike_in_valid), .decay_pulse(1'b0), .data_a(n00_a), .data_b(spike_in_data_b), .mac_en(spike_in_valid), .mac_clr(1'b0), .mac_out(n00_out), .stress_reg(node00_stress));
    SwarmNode n01 (.clk(clk), .rst_n(rst_n), .spike_in(backpressure), .decay_pulse(1'b0), .data_a(n01_a), .data_b(spike_in_data_b), .mac_en(backpressure), .mac_clr(1'b0), .mac_out(n01_out), .stress_reg());
    SwarmNode n11 (.clk(clk), .rst_n(rst_n), .spike_in(1'b1), .decay_pulse(1'b0), .data_a(8'd1), .data_b(8'd1), .mac_en(1'b1), .mac_clr(1'b0), .mac_out(spike_out_final), .stress_reg());

endmodule