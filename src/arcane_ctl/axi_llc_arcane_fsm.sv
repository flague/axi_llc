// Copyright 2025 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: axi_llc_arcane_fsm.sv
// Author: Flavia Guella
// Date: 11/06/2025

module axi_llc_arcane_fsm (
  input  logic clk_i,
  input  logic rst_ni,

  // Locking mechanism
  // -----------------
  input  logic ecpu_lock_i,
  input  logic ecpu_lock_req_i,
  output logic ready_lock_o,

  // Isolate LLC
  // -----------
  input  logic llc_isolated_i,
  input  logic ar_unit_busy_i,
  input  logic aw_unit_busy_i,
  output logic llc_isolate_o
);

// Internal signals
// ----------------

typedef enum logic [2:0] {
  IDLE = 3'b000,
  ISOLATE = 3'b001,
  LOCK = 3'b010,
  LOCK_ERR = 3'b011 // debugging state, for error handling
} state_t;

state_t curr_state, next_state;

// TODO: IMPORTANT
// manage the case of multiple acquires or releases of the lock
// This should be done in the ctl_reg logic itself (Read and compare),
// Dn't make any req if w_data=r_data

// Critical case: the isolation can be also required when flushing, what happens in this case?
// If in IDLE: at a certain point !ecpi_lock_req && llc_isolated_i
//----------------
// State evolution
//----------------
always_comb begin
  case (curr_state)
    IDLE: begin
      if (ecpu_lock_req_i && !ecpu_lock_i && !llc_isolated_i) begin
        // eCPU requests to lock (set), and llc is not isolated
        next_state = ISOLATE;
      end else if (ecpu_lock_req_i && !ecpu_lock_i && llc_isolated_i) begin
        // LLC is already isolated (should not happen)
        if (!ar_unit_busy_i && !aw_unit_busy_i) begin
          // If the LLC is isolated and both units are not busy, we can go to LOCK state
          next_state = LOCK;
        end else begin
          // If the LLC is isolated but one of the units is busy, wait until they are free
          next_state = ISOLATE;
        end
      end else if (!ecpu_lock_req_i) begin
        if (ecpu_lock_i && llc_isolated_i) begin
          // eCPU is locked, LLC is isolated, but no request to lock
          // should never happen
          next_state = LOCK; // Remain in LOCK state
        end else begin
          next_state = IDLE;
        end
      end else begin
        // Illegal combinations
        next_state = LOCK_ERR;
      end
    end
    ISOLATE: begin
      // TODO: for error handling could also check there is still a ecpu_lock_req, otherwise give error
      // Wait until the LLC is isolated to proceed with the lock
      if (llc_isolated_i && !ar_unit_busy_i && !aw_unit_busy_i)
        next_state = LOCK;
      else
        next_state = ISOLATE;
    end
    LOCK: begin
      // Remain in this state until a request to unlock is received
      if (ecpu_lock_i && ecpu_lock_req_i) begin
        next_state = IDLE;
      end else if (!ecpu_lock_i) begin
        // If the eCPU requests a lock but is not locked, go to error state
        next_state = LOCK_ERR;
      end else if (!llc_isolated_i) begin
        // If the LLC is not isolated, go to error state
        next_state = LOCK_ERR;
      end else begin
        // Remain in LOCK state
        next_state = LOCK;
      end
    end
    LOCK_ERR: begin
      // Error state, could be used for debugging or error handling
      // For now, just stay in this state until reset
      next_state = LOCK_ERR;
    end
    default: begin
      // Default case to handle unexpected states
      next_state = IDLE;
    end
  endcase
end


//---------------
// Output network
//---------------
always_comb begin
  // Default values
  ready_lock_o = 1'b0;  // Do not give the lock to eCPU
  llc_isolate_o = 1'b0; // Do not isolate the LLC

  case(curr_state)
    IDLE: begin
      ready_lock_o  = llc_isolated_i & ~aw_unit_busy_i & ~ar_unit_busy_i & ~ecpu_lock_i; // Mealy
      //llc_isolate_o = ecpu_lock_req_i & ~ecpu_lock_i; // Mealy
    end
    ISOLATE: begin
      ready_lock_o  = llc_isolated_i & ~aw_unit_busy_i & ~ar_unit_busy_i; // Mealy
      //llc_isolate_o = 1'b1;
    end
    LOCK: begin
      ready_lock_o  = 1'b1; // Ready to unlock if required
      //llc_isolate_o = ~ecpu_lock_req_i & ecpu_lock_i; // Keep LLC isolated until request to unlock
    end
    LOCK_ERR: begin
      // In error state, do not change the lock or isolation status
      //llc_isolate_o = 1'b1; // Isolate LLC if not isolate
    end
    default: begin
      // Default case to handle unexpected states
    end
  endcase
end

//---------------
// State Register
//---------------
always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    curr_state <= IDLE; // Reset to IDLE state
  end else begin
    curr_state <= next_state; // Update to the next state
  end
end


endmodule