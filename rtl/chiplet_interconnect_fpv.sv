// =========================================================================
// SANE-6G: Multi-Chiplet CXL Link-Layer Cryptographic Isolation Proofs
// Objective: Formal containment of physical interconnect interception
// =========================================================================

module chiplet_interconnect_fpv (
    input  logic        clk_link,
    input  logic        rst_link_n,
    
    // --- Internal Interface (Untrusted Domain) ---
    input  logic        tx_plaintext_valid,
    input  logic [255:0] tx_plaintext_data,
    
    // --- External Physical Pins (Adversarial Exposure Domain) ---
    input  logic        cxl_tx_valid,
    input  logic [255:0] cxl_tx_data,
    
    // --- Cryptographic Key Management Control ---
    input  logic        key_rotation_strobe,
    input  logic [255:0] aes_active_session_key,
    input  logic [255:0] sdm_puf_entropy_bus
);

    // -------------------------------------------------------------------------
    // PROOF 1: Strict Plaintext Leakage Elimination
    // -------------------------------------------------------------------------
    property p_plaintext_isolation;
        @(posedge clk_link) disable iff (!rst_link_n)
        (tx_plaintext_valid && (tx_plaintext_data != '0)) |-> (cxl_tx_data != tx_plaintext_data);
    endproperty
    prove_plaintext_isolation: assert property (p_plaintext_isolation)
        else $error("CRITICAL EXPLOIT DETECTED: Plaintext data leaked directly to external interconnect pins!");

    // -------------------------------------------------------------------------
    // PROOF 2: Entropy-Bound Key Mutation
    // -------------------------------------------------------------------------
    property p_enforced_key_rotation;
        @(posedge clk_link) disable iff (!rst_link_n)
        (key_rotation_strobe) |=> (aes_active_session_key != $past(aes_active_session_key)) && 
                                  (aes_active_session_key == (sdm_puf_entropy_bus ^ $past(aes_active_session_key)));
    endproperty
    prove_enforced_key_rotation: assert property (p_enforced_key_rotation)
        else $error("CRYPTOGRAPHIC FAULT: Key rotation sequence compromised or stagnant key detected.");

endmodule
