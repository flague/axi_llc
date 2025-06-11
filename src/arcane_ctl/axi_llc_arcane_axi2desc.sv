// Copyright 2025 EPFL.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: axi_llc_arcane_axi2desc.sv
// Author: Flavia Guella
// Date: 09/06/2025
// Similar to axi_llc_chan_splitter

module axi_llc_arcane_axi2desc #(
  /// Static LLC parameter configuration.
  parameter axi_llc_pkg::llc_cfg_t Cfg = axi_llc_pkg::llc_cfg_t'{default: '0},
  /// Required struct definition in: `axi_llc_pkg`.
  parameter axi_llc_pkg::llc_axi_cfg_t AxiCfg = axi_llc_pkg::llc_axi_cfg_t'{default: '0},
  parameter type chan_t = logic,
  /// This defines if the unit is on the AW or the AR channel
  /// AW: 1
  /// AR: 0
  parameter bit Write = 1'b1,
  parameter type desc_t = logic,
  /// Type of the address rule struct used for SPM access streering
  parameter type rule_t = axi_pkg::xbar_rule_64_t
) (
  input  logic clk_i,
  input  logic rst_ni,
  // AXI AX slave channel payload
  // -----------------------------
  input  chan_t ax_chan_i,
  // AXI AX slave channel valid
  input  logic ax_chan_valid_i,
  // AXI AX slave channel ready
  output logic ax_chan_ready_o,
  // Type of transfer for src or dst
  // -------------------------------
  input logic src_dst_i,
  // Generated output descriptor payload
  // -----------------------------------
  output desc_t desc_o,
  // Descriptor is valid
  output logic desc_valid_o,
  // Downstream unit is ready for a descriptor
  input  logic desc_ready_i,
  // Addr rule for cached region
  // ---------------------------
  input rule_t cached_rule_i
);

// Internal signals
// ----------------
typedef enum logic [1:0] {
  IDLE,          // Idle state, waiting for valid AXI channel
  WAIT_DOWNSTREAM
 } state_t;

state_t curr_state, next_state; // State registers

// Descriptors
desc_t desc_d, desc_q; // Descriptor data and output
logic load_desc; // When to load descriptor
logic alloc_src; // When to allocate source
logic writeback; // When to write back data

//------------------
// Address converter
//------------------

// ARCANE-Way idx converter
// ------------------------
// Given a physical address, convert it to set and way index of the cache
///// TODO
// assign ct_update_instance_idx[1] = sw_dma_write_req_i.addr[(VrfIdxEndBit-1)-:InstanceIdxW];
// assign ct_update_line_idx[1] = sw_dma_write_req_i.addr[VrfIdxEndBit-InstanceIdxW-1:LineAddrW];
// assign set_idx_o      = {instance_idx_i, line_idx_i[LineIdxW-1:WayIdxW]};
// assign way_idx_o      = line_idx_i[WayIdxW-1:0];
// Look at burst_cutter and the decoder in spm mode and do something similar here
//////////////////////////
// addr decode signals
//localparam int unsigned RuleIndexWidth = (Cfg.SetAssociativity > 1) ? $clog2(Cfg.SetAssociativity) : 1;
//logic                      way_idx_valid;
//logic [RuleIndexWidth-1:0] way_idx; // so that width matches decoder port
//// generate the addr map for the decoder, ram has rule 0 and each way has one for its spm region
//rule_t [Cfg.SetAssociativity:0] way_addr_map;
//always_comb begin : proc_assign_addr_map
//  addr_t tmp_addr;                  // this counts up for the spm regions, one for each way
//  tmp_addr = Carus0StartAddr; // init tmp_addr
//  way_addr_map = '0;
//  // assign the spm regions
//  for (int unsigned i = 32'd0; i < Cfg.SetAssociativity; i++) begin
//    way_addr_map[i].idx        = i;
//    way_addr_map[i].start_addr = tmp_addr;
//    way_addr_map[i].end_addr   = tmp_addr + (Cfg.BlockSize / 32'd8) * Cfg.NumBlocks * Cfg.NumLines;
//    tmp_addr               = tmp_addr + (Cfg.BlockSize / 32'd8) * Cfg.NumBlocks * Cfg.NumLines;
//  end
//end
//
//addr_decode #(
//  .NoIndices ( Cfg.SetAssociativity),
//  .NoRules   ( Cfg.SetAssociativity),
//  .addr_t    ( addr_t              ),
//  .rule_t    ( rule_t              )
//) i_arcane_llc_way_decode (
//  .addr_i           ( ax_chan_i.addr  ),
//  .addr_map_i       ( way_addr_map    ),
//  .idx_o            ( way_idx         ),
//  .dec_valid_o      ( way_idx_valid   ),
//  .dec_error_o      ( /*not used*/    ), // implicit used in rule_valid
//  .en_default_idx_i ( 1'b0            ),
//  .default_idx_i    ( '0              )
//);
localparam int unsigned    WayIdxLength = (Cfg.SetAssociativity > 1) ? $clog2(Cfg.SetAssociativity) : 1;
logic [WayIdxLength-1:0] way_idx_bin; // so that width matches decoder port
logic [Cfg.SetAssociativity-1:0] way_idx_onehot; // way index of the cache in onehot format
//logic [Cfg.IndexLength-1:0] set_idx; // set index of the cache

//assign set_idx = ax_chan_i.addr[Cfg.BlockOffsetLength + Cfg.ByteOffsetLength +: Cfg.IndexLength];
assign way_idx_bin = ax_chan_i.addr[Cfg.BlockOffsetLength + Cfg.ByteOffsetLength + Cfg.IndexLength +: WayIdxLength];

// convert the way index to onehot format
// TODO: a more dirty way to do this saving a shifter is
// adding a field to desc_t with the way idx in bin format
// and use directly it for the special ARCANE ops
bin_to_onehot #(
  .BIN_WIDTH ( WayIdxLength ),
  .ONEHOT_WIDTH ( Cfg.SetAssociativity )
) i_arcane_way_idx_conv (
  .bin(way_idx_bin),
  .onehot(way_idx_onehot)
);


// ARCANE-DRAM decoder
// -------------------
// On alloc_src, write to physical llc, read from mem space
// TODO: understand what should be the addresses of these regions
// MSBs (keep this part constant in the map to avoid complex logic and comparators)
// eg. F0........ vs 00......., restrict the comparison to 4 msb at most
// Cached mem region is identified by cached_start_addr and cached_end_addr

// generate the addr map for the decoder, ram has rule 0 and each way has one for its spm region
rule_t [1:0] addr_map;  
logic rule_valid;
logic rule_index; // distinguish between arcane and main mem region
localparam int unsigned LLCSize = Cfg.SetAssociativity*Cfg.BlockSize / 32'd8 * Cfg.NumBlocks * Cfg.NumLines; // size of the LLC in bytes
typedef logic [AxiCfg.AddrWidthFull-1:0] addr_t; // address type
// assign the ram range
assign addr_map[0].start_addr = cached_rule_i.start_addr;
assign addr_map[0].end_addr   = cached_rule_i.end_addr;
assign addr_map[1].start_addr = axi_llc_pkg::Carus0StartAddr;
assign addr_map[1].end_addr   = axi_llc_pkg::Carus0StartAddr + LLCSize;
  
addr_decode #(
  .NoIndices ( 32'd2 ),
  .NoRules   ( 32'd2 ),
  .addr_t    ( addr_t                       ),
  .rule_t    ( rule_t                       )
) i_arcane_llc_mem_decode (
  .addr_i           ( ax_chan_i.addr   ),
  .addr_map_i       ( addr_map         ),
  .idx_o            ( rule_index       ),
  .dec_valid_o      ( rule_valid       ),
  .dec_error_o      ( /*not used*/     ), // implicit used in rule_valid
  .en_default_idx_i ( 1'b0             ),
  .default_idx_i    ( '0               )
);

assign alloc_src = (Write) ?  src_dst_i & rule_index : src_dst_i & ~rule_index;
// On writeback, write to mem space, read from physical llc
assign writeback = (Write) ?  ~rule_index : rule_index;

//assign alloc_src = (Write) ?  src_dst_i & ax_chan_i.addr[AxiCfg.AddrWidthFull-1:VirtAddrOffset] ==
//                                          Carus0StartAddr[AxiCfg.AddrWidthFull-1:VirtAddrOffset] :
//                              src_dst_i & ax_chan_i.addr[AxiCfg.AddrWidthFull-1:VirtAddrOffset] ==
//                                          MainMem0StartAddr[AxiCfg.AddrWidthFull-1:VirtAddrOffset];
//// On writeback, write to mem space, read from physical llc
//assign writeback = (Write) ?  ax_chan_i.addr[AxiCfg.AddrWidthFull-1:VirtAddrOffset] ==
//                                MainMem0StartAddr[AxiCfg.AddrWidthFull-1:VirtAddrOffset] :
//                              ax_chan_i.addr[AxiCfg.AddrWidthFull-1:VirtAddrOffset] ==
//                                Carus0StartAddr[AxiCfg.AddrWidthFull-1:VirtAddrOffset];
assign desc_d = desc_t'{
        a_x_id:    ax_chan_i.id,
        a_x_addr:  ax_chan_i.addr,
        a_x_size:  ax_chan_i.size,
        a_x_burst: ax_chan_i.burst,
        a_x_lock:  ax_chan_i.lock,
        a_x_prot:  ax_chan_i.prot,
        a_x_cache: ax_chan_i.cache,
        a_x_len:   1'b1, // transefer 1 word/beat
        x_resp:    axi_pkg::RESP_OKAY,
        x_last:    1'b1,
        //spm:     1'b0,
        rw:        Write,
        way_ind:   way_idx_onehot, // way index of the cache in onehot format (leave empty)
        //evict:,
        //evict_tag:,
        //refill:,
        //flush:     1'b0,
        alloc_src: alloc_src,
        writeback: writeback,
        default: '0
  };

// State machine logic
// -------------------
always_comb begin
  case (curr_state)
    IDLE: begin
      if (ax_chan_valid_i && desc_ready_i)
        next_state = WAIT_DOWNSTREAM;
      else
        next_state = IDLE;
    end
    WAIT_DOWNSTREAM: begin
      if (desc_ready_i)
        next_state = IDLE; // Transition back to IDLE after processing
      else
        next_state = WAIT_DOWNSTREAM; // Stay in WAIT_DOWNSTREAM until ready
    end
    default: begin
      next_state = IDLE; // Default transition to IDLE state
    end
  endcase
end

// Output network
// --------------
always_comb begin
  // Default assignments
  ax_chan_ready_o = 1'b0;
  desc_valid_o    = 1'b0;
  load_desc       = 1'b0; // Load descriptor flag
  desc_o          = desc_d; // Default descriptor output
  case (curr_state)
    IDLE: begin
      ax_chan_ready_o = 1'b1; // Ready to accept AXI channel
      desc_valid_o    = ax_chan_valid_i; // Mealy
      load_desc       = 1'b1;
      desc_o          = desc_d;
    end
    WAIT_DOWNSTREAM: begin
      desc_valid_o    = 1'b1; // Descriptor is valid
      desc_o          = desc_q; // Assign the AXI channel to the descriptor output
    end
    default: begin
      ax_chan_ready_o = 1'b0; // Default not ready for AXI channel
      desc_valid_o    = 1'b0; // Default no descriptor valid
      desc_o          = desc_d;
    end
  endcase
end


// State registers
// ---------------
always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    curr_state <= IDLE;
  end else begin
    curr_state <= next_state;
  end
end

// Output registers
// ----------------
always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    desc_q          <= '0; // Reset descriptor output
  end else if (load_desc) begin
    desc_q          <= desc_d; // Update descriptor output
  end
end

endmodule
