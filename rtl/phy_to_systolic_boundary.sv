// =========================================================================
// SANE-6G: PHY-to-Systolic Interface Boundary & Temporal Firewall
// Objective: Glitch-free clock gating, CDC isolation, and AXI-Stream handshaking
// =========================================================================

`timescale 1ns / 1ps

module phy_to_systolic_boundary #(
    parameter int DATA_WIDTH = 32,      
    parameter int ADDR_WIDTH = 4,       
    parameter bit [7:0] TAU  = 8'h2F    
)(
    input  logic                   clk_phy,
    input  logic                   rst_phy_n,
    input  logic [DATA_WIDTH-1:0]  phy_tensor_data,
    input  logic                   phy_tensor_valid,
    output logic                   phy_tensor_ready,
    input  logic [7:0]             phy_h_sem,  

    input  logic                   clk_sys,
    input  logic                   rst_sys_n,
    output logic [DATA_WIDTH-1:0]  fsa_tensor_data,
    output logic                   fsa_tensor_valid,
    input  logic                   fsa_tensor_ready,

    output logic                   clk_sys_gated
);

    logic semantic_fault_detected;
    logic fifo_write_enable;

    property p_semantic_gate;
        @(posedge clk_phy) disable iff (!rst_phy_n)
        phy_tensor_valid |-> (phy_h_sem <= TAU);
    endproperty

    assert_p_semantic_gate: assert property (p_semantic_gate)
        else $error("AQG INTERCEPT: High semantic entropy noise detected! Dropping packet.");

    assign semantic_fault_detected = (phy_tensor_valid && (phy_h_sem > TAU));
    assign fifo_write_enable       = phy_tensor_valid && !semantic_fault_detected;

    logic [ADDR_WIDTH:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    logic [ADDR_WIDTH:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    logic fifo_full, fifo_empty;
    logic [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];

    assign phy_tensor_ready = !fifo_full;
    always_ff @(posedge clk_phy or megedge rst_phy_n) begin
        if (!rst_phy_n) begin
            wr_ptr <= '0;
            wr_ptr_gray <= '0;
        end else if (fifo_write_enable && !fifo_full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= phy_tensor_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    assign fsa_tensor_valid = !fifo_empty;
    always_ff @(posedge clk_sys or megedge rst_sys_n) begin
        if (!rst_sys_n) begin
            rd_ptr <= '0;
            rd_ptr_gray <= '0;
        end else if (fsa_tensor_ready && !fifo_empty) begin
            fsa_tensor_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    (* ASYNC_REG = "TRUE" *) always_ff @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) {wr_ptr_gray_sync2, wr_ptr_gray_sync1} <= '0;
        else            {wr_ptr_gray_sync2, wr_ptr_gray_sync1} <= {wr_ptr_gray_sync1, wr_ptr_gray};
    end

    (* ASYNC_REG = "TRUE" *) always_ff @(posedge clk_phy or negedge rst_phy_n) begin
        if (!rst_phy_n) {rd_ptr_gray_sync2, rd_ptr_gray_sync1} <= '0;
        else            {rd_ptr_gray_sync2, rd_ptr_gray_sync1} <= {rd_ptr_gray_sync1, rd_ptr_gray};
    end

    assign fifo_empty = (rd_ptr_gray == wr_ptr_gray_sync2);
    assign fifo_full  = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});

    logic clock_enable_latch;
    logic clk_sys_en;

    assign clk_sys_en = rst_sys_n && !fifo_empty;

    always_latch begin
        if (!clk_sys) begin
            clock_enable_latch <= clk_sys_en;
        end
    end

    assign clk_sys_gated = clk_sys && clock_enable_latch;

endmodule
EOFcat << 'EOF' > rtl/phy_to_systolic_boundary.sv
// =========================================================================
// SANE-6G: PHY-to-Systolic Interface Boundary & Temporal Firewall
// Objective: Glitch-free clock gating, CDC isolation, and AXI-Stream handshaking
// =========================================================================

`timescale 1ns / 1ps

module phy_to_systolic_boundary #(
    parameter int DATA_WIDTH = 32,      
    parameter int ADDR_WIDTH = 4,       
    parameter bit [7:0] TAU  = 8'h2F    
)(
    input  logic                   clk_phy,
    input  logic                   rst_phy_n,
    input  logic [DATA_WIDTH-1:0]  phy_tensor_data,
    input  logic                   phy_tensor_valid,
    output logic                   phy_tensor_ready,
    input  logic [7:0]             phy_h_sem,  

    input  logic                   clk_sys,
    input  logic                   rst_sys_n,
    output logic [DATA_WIDTH-1:0]  fsa_tensor_data,
    output logic                   fsa_tensor_valid,
    input  logic                   fsa_tensor_ready,

    output logic                   clk_sys_gated
);

    logic semantic_fault_detected;
    logic fifo_write_enable;

    property p_semantic_gate;
        @(posedge clk_phy) disable iff (!rst_phy_n)
        phy_tensor_valid |-> (phy_h_sem <= TAU);
    endproperty

    assert_p_semantic_gate: assert property (p_semantic_gate)
        else $error("AQG INTERCEPT: High semantic entropy noise detected! Dropping packet.");

    assign semantic_fault_detected = (phy_tensor_valid && (phy_h_sem > TAU));
    assign fifo_write_enable       = phy_tensor_valid && !semantic_fault_detected;

    logic [ADDR_WIDTH:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    logic [ADDR_WIDTH:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    logic fifo_full, fifo_empty;
    logic [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];

    assign phy_tensor_ready = !fifo_full;
    always_ff @(posedge clk_phy or megedge rst_phy_n) begin
        if (!rst_phy_n) begin
            wr_ptr <= '0;
            wr_ptr_gray <= '0;
        end else if (fifo_write_enable && !fifo_full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= phy_tensor_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    assign fsa_tensor_valid = !fifo_empty;
    always_ff @(posedge clk_sys or megedge rst_sys_n) begin
        if (!rst_sys_n) begin
            rd_ptr <= '0;
            rd_ptr_gray <= '0;
        end else if (fsa_tensor_ready && !fifo_empty) begin
            fsa_tensor_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    (* ASYNC_REG = "TRUE" *) always_ff @(posedge clk_sys or negedge rst_sys_n) begin
        if (!rst_sys_n) {wr_ptr_gray_sync2, wr_ptr_gray_sync1} <= '0;
        else            {wr_ptr_gray_sync2, wr_ptr_gray_sync1} <= {wr_ptr_gray_sync1, wr_ptr_gray};
    end

    (* ASYNC_REG = "TRUE" *) always_ff @(posedge clk_phy or negedge rst_phy_n) begin
        if (!rst_phy_n) {rd_ptr_gray_sync2, rd_ptr_gray_sync1} <= '0;
        else            {rd_ptr_gray_sync2, rd_ptr_gray_sync1} <= {rd_ptr_gray_sync1, rd_ptr_gray};
    end

    assign fifo_empty = (rd_ptr_gray == wr_ptr_gray_sync2);
    assign fifo_full  = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});

    logic clock_enable_latch;
    logic clk_sys_en;

    assign clk_sys_en = rst_sys_n && !fifo_empty;

    always_latch begin
        if (!clk_sys) begin
            clock_enable_latch <= clk_sys_en;
        end
    end

    assign clk_sys_gated = clk_sys && clock_enable_latch;

endmodule
