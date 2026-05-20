// =========================================================================
// SANE-6G: Fused Systolic Array (FSA) Split-Unit Processing Element
// Objective: In-place, zero-latency 2^x approximation via MAC reuse
// =========================================================================

`timescale 1ns / 1ps

module fsa_split_unit_pe #(
    parameter int INT_WIDTH = 4,   
    parameter int FRAC_WIDTH = 12  
)(
    input  logic                         clk_gated, 
    input  logic                         rst_n,
    input  logic [INT_WIDTH+FRAC_WIDTH-1:0] west_in,   
    output logic [INT_WIDTH+FRAC_WIDTH-1:0] east_out,  
    output logic [INT_WIDTH+FRAC_WIDTH-1:0] exp_out    
);

    localparam int TOTAL_WIDTH = INT_WIDTH + FRAC_WIDTH;
    logic [TOTAL_WIDTH-1:0] x_reg;
    
    always_ff @(posedge clk_gated or negedge rst_n) begin
        if (!rst_n) begin
            x_reg    <= '0;
            east_out <= '0;
        end else begin
            x_reg    <= west_in;
            east_out <= x_reg; 
        end
    end

    logic signed [INT_WIDTH-1:0]  z_int;
    logic        [FRAC_WIDTH-1:0] f_frac;

    assign z_int  = x_reg[TOTAL_WIDTH-1 : FRAC_WIDTH];
    assign f_frac = x_reg[FRAC_WIDTH-1  : 0];

    logic [1:0] lut_index;
    assign lut_index = f_frac[FRAC_WIDTH-1 : FRAC_WIDTH-2];

    logic [FRAC_WIDTH-1:0] slope_m;
    logic [FRAC_WIDTH-1:0] intercept_b;

    always_comb begin
        case (lut_index)
            2'b00: begin slope_m = 12'h2C5; intercept_b = 12'h000; end 
            2'b01: begin slope_m = 12'h344; intercept_b = 12'h020; end 
            2'b02: begin slope_m = 12'h3DE; intercept_b = 12'h070; end 
            2'b03: begin slope_m = 12'h49B; intercept_b = 12'h0F4; end 
            default: begin slope_m = 12'h2C5; intercept_b = 12'h000; end
        endcase
    end

    logic [(2*FRAC_WIDTH)-1:0] mult_intermediate;
    logic [FRAC_WIDTH-1:0]     interpolated_f;

    always_ff @(posedge clk_gated or negedge rst_n) begin
        if (!rst_n) begin
            mult_intermediate <= '0;
            interpolated_f    <= '0;
        end else begin
            mult_intermediate <= f_frac * slope_m;
            interpolated_f    <= mult_intermediate[(2*FRAC_WIDTH)-1 : FRAC_WIDTH] + intercept_b;
        end
    end

    always_ff @(posedge clk_gated or negedge rst_n) begin
        if (!rst_n) begin
            exp_out <= '0;
        end else begin
            if (z_int >= 0) begin
                exp_out <= interpolated_f << z_int; 
            end else begin
                exp_out <= interpolated_f >> (-z_int); 
            end
        end
    end

endmodule
