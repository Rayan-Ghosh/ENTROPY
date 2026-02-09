module SwarmNode (
    clk,
    rst_n,
    spike_in,
    decay_pulse,
    data_a,
    data_b,
    mac_en,
    mac_clr,
    mac_out,
    stress_reg
);

    // 1. Port Directions
    input         clk;
    input         rst_n;
    input         spike_in;
    input         decay_pulse;
    input  [7:0]  data_a;
    input  [7:0]  data_b;
    input         mac_en;
    input         mac_clr;
    output [15:0] mac_out;
    output [7:0]  stress_reg;

    // 2. Data Type Definitions
    reg [15:0] mac_out;
    reg [7:0]  stress_reg;
    reg [15:0] accumulator;
    wire [15:0] product;

    // 3. STRESS LOGIC (Homeostasis)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stress_reg <= 8'h00;
        end else begin
            if (spike_in && (stress_reg < 8'hFF)) begin
                stress_reg <= (stress_reg > 8'd250) ? 8'hFF : (stress_reg + 8'd5);
            end else if (decay_pulse && (stress_reg > 0)) begin
                stress_reg <= stress_reg - 8'd1;
            end
        end
    end

    // 4. MAC UNIT
    assign product = data_a * data_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= 16'h0000;
        end else if (mac_clr) begin
            accumulator <= 16'h0000;
        end else if (mac_en) begin
            accumulator <= accumulator + product;
        end
    end

    // 5. ADAPTIVE PRECISION (Biomimetic Power Saving)
    // Zeroes the 8 LSBs when stressed to reduce switching activity (alpha)
    always @(*) begin
        if (stress_reg > 8'd200) begin
            mac_out = {accumulator[15:8], 8'h00}; 
        end else begin
            mac_out = accumulator;
        end
    end

endmodule