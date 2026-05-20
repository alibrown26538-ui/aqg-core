// =========================================================================
// SANE-6G: Formal Property Verification (FPV) Proof Harness
// Objective: Absolute mathematical containment of The Riddle Protocol
// =========================================================================

module phy_to_systolic_fpv (
    input  logic        clk_phy,
    input  logic        rst_phy_n,
    input  logic        phy_tensor_valid,
    input  logic [7:0]  phy_h_sem,
    input  logic        fifo_write_enable,
    input  logic [4:0]  wr_ptr_gray,

    input  logic        clk_sys,
    input  logic        rst_sys_n,
    input  logic [4:0]  wr_ptr_gray_sync2,
    input  logic        fifo_empty,
    input  logic        clock_enable_latch,
    input  logic        clk_sys_gated
);

    assume_phy_clk_stable: assume property (@(posedge clk_phy) 1'b1);
    assume_sys_clk_stable: assume property (@(posedge clk_sys) 1'b1);

    assume_phy_reset_release: assume property (@(posedge clk_phy) $fell(rst_phy_n) |-> ##[1:5] $rose(rst_phy_n));
    assume_sys_reset_release: assume property (@(posedge clk_sys) $fell(rst_sys_n) |-> ##[1:5] $rose(rst_sys_n));

    property p_instantaneous_drop;
        @(posedge clk_phy) (phy_tensor_valid && (phy_h_sem > 8'h2F)) |-> (fifo_write_enable == 1'b0);
    endproperty
    prove_instantaneous_drop: assert property (p_instantaneous_drop);

    property p_gray_code_continuous;
        @(posedge clk_phy) disable iff (!rst_phy_n)
        $changed(wr_ptr_gray) |-> ($countones(wr_ptr_gray ^ $past(wr_ptr_gray)) == 1);
    endproperty
    prove_gray_code_continuous: assert property (p_gray_code_continuous);

    property p_safe_latch_state;
        @(clk_sys) (rst_sys_n) |-> !$isunknown(clock_enable_latch);
    endproperty
    prove_safe_latch_state: assert property (p_safe_latch_state);

    property p_clock_liveness;
        @(posedge clk_sys) disable iff (!rst_sys_n)
        (!fifo_empty) |-> s_eventually (clk_sys_gated == 1'b1);
    endproperty
    prove_clock_liveness: assert property (p_clock_liveness);

    property p_no_fifo_overrun;
        @(posedge clk_phy) disable iff (!rst_phy_n)
        (wr_ptr_gray == {~wr_ptr_gray_sync2[4:3], wr_ptr_gray_sync2[2:0]}) |-> (fifo_write_enable == 1'b0);
    endproperty
    prove_no_fifo_overrun: assert property (p_no_fifo_overrun);

    cover_valid_data_traverse: cover property (
        @(posedge clk_phy) (phy_tensor_valid && (phy_h_sem <= 8'h2F)) ##[1:20] 
        @(posedge clk_sys) (fifo_empty == 1'b0)
    );

endmodule
