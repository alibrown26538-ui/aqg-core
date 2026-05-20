// =========================================================================
// SANE-6G: Fused Systolic Array (FSA) Pipelined Rowsum Accumulator
// Objective: Spatial, zero-stall accumulation of the Softmax denominator
// =========================================================================

`timescale 1ns / 1ps

module fsa_systolic_rowsum #(
    parameter int N_COLS = 16,        
    parameter int DATA_WIDTH = 32     
)(
    input  logic                    clk_sys,
    input  logic                    rst_sys_n,
    input  logic                    row_enable,                  
    input  logic [DATA_WIDTH-1:0]   exp_out [0:N_COLS-1],        
    output logic [DATA_WIDTH-1:0]   final_rowsum,                
    output logic                    final_rowsum_valid           
);

    logic [DATA_WIDTH-1:0] acc_pipe [0:N_COLS-1];
    logic                  valid_pipe [0:N_COLS-1];

    always_ff @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            for (int i = 0; i < N_COLS; i++) begin
                acc_pipe[i]   <= '0;
                valid_pipe[i] <= 1'b0;
            end
        end else if (row_enable) begin
            acc_pipe   <= exp_out;
            valid_pipe <= 1'b1; 

            for (int i = 1; i < N_COLS; i++) begin
                acc_pipe[i]   <= acc_pipe[i-1] + exp_out[i];
                valid_pipe[i] <= valid_pipe[i-1];
            end
        end else begin
            for (int i = 0; i < N_COLS; i++) begin
                valid_pipe[i] <= 1'b0;
            end
        end
    end

    assign final_rowsum       = acc_pipe[N_COLS-1];
    assign final_rowsum_valid = valid_pipe[N_COLS-1];

endmodule
