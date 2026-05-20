// =========================================================================
// SANE-6G: Hybrid Photonic-Electronic Boundary Interface
// Compliance: High-Speed Mixed-Signal CDC Verification Guidelines
// Objective: Sub-nanosecond, deterministic O-E handoff without ADC bottlenecks
// =========================================================================

`timescale 1ps / 1fs

module photonic_electronic_handoff #(
    parameter int TENSOR_WIDTH = 32
)(
    input  wire                     optical_pulse_valid,
    input  wire  [TENSOR_WIDTH-1:0] optical_photocurrent_val,
    input  logic                    clk_sys,
    input  logic                    rst_n,
    output logic [TENSOR_WIDTH-1:0] split_unit_data,
    output logic                    split_unit_valid
);

    logic                    async_pulse_caught;
    logic [TENSOR_WIDTH-1:0] async_latched_data;
    logic                    sync_clear_clk_phy;

    always_ff @(posedge optical_pulse_valid or posedge sync_clear_clk_phy or negedge rst_n) begin
        if (!rst_n) begin
            async_pulse_caught <= 1'b0;
            async_latched_data <= '0;
        end else if (sync_clear_clk_phy) begin
            async_pulse_caught <= 1'b0;
        end else begin
            async_pulse_caught <= 1'b1;
            async_latched_data <= optical_photocurrent_val;
        end
    end

    (* ASYNC_REG = "TRUE" *) logic sync_reg1, sync_reg2, sync_reg3;

    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 1'b0;
            sync_reg2 <= 1'b0;
            sync_reg3 <= 1'b0;
        end else begin
            sync_reg1 <= async_pulse_caught;
            sync_reg2 <= sync_reg1;
            sync_reg3 <= sync_reg2;
            end
    end

    logic sync_pulse_edge;
    assign sync_pulse_edge = sync_reg2 && !sync_reg3;

    logic sync_clear_req;

    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            split_unit_data  <= '0;
            split_unit_valid <= 1'b0;
            sync_clear_req   <= 1'b0;
        end else begin
            if (sync_pulse_edge) begin
                split_unit_data  <= async_latched_data;
                split_unit_valid <= 1'b1;
                sync_clear_req   <= 1'b1;
            end else begin
                split_unit_valid <= 1'b0;
                sync_clear_req   <= 1'b0;
            end
        end
    end

    assign sync_clear_clk_phy = sync_clear_req;

    property p_optical_latency_bound;
        @(posedge clk_sys) disable iff (!rst_n)
        sync_pulse_edge |-> ##1 (split_unit_valid == 1'b1);
    endproperty
    assert_optical_latency: assert property (p_optical_latency_bound);

    property p_oe_signal_integrity;
        @(posedge clk_sys) disable iff (!rst_n)
        (split_unit_valid) |-> !$isunknown(split_unit_data);
    endproperty
    assert_oe_signal_integrity: assert property (p_oe_signal_integrity);

endmodule
