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
// File: axi_llc_arcane_ctl.sv
// Author: Flavia Guella
// Date: 10/06/2025

module axi_llc_arcane_ctl #(
  /// LLC configuration struct, with static parameters.
  parameter axi_llc_pkg::llc_cfg_t     Cfg    = axi_llc_pkg::llc_cfg_t'{default: '0},
  /// AXI channel configuration struct.
  parameter axi_llc_pkg::llc_axi_cfg_t AxiCfg = axi_llc_pkg::llc_axi_cfg_t'{default: '0},
  /// Descriptor type to be forwarded to the hit/miss unit
  parameter type desc_t = logic,
  /// Groups W/R/B requests together
  parameter type axi_data_req_t = logic,
  /// Groups W/R/B responses together
  parameter type axi_data_resp_t = logic,
  /// Address rule type definitions for the AXI slave port.
  parameter type rule_t = axi_pkg::xbar_rule_64_t,
  /// Register interface types
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  
  // eCPU interface
  // --------------
  /// DMA interface
  input  reg_req_t dma_reg_req_i,
  output reg_rsp_t dma_reg_rsp_o,
  /// Src/Dst allocation signals
  input  logic ecpu_src_dst_alloc_i,
  /// Locking signals
  input  logic ecpu_llc_lock_i,
  input  logic ecpu_llc_lock_req_i,
  output logic arcane_llc_lock_o,
  
  // AXI_isolate interface
  // ---------------------
  output logic llc_isolate_o,
  input  logic llc_isolated_i,

  // R/W splitter interface
  // -----------------------
  input  logic aw_unit_busy_i,
  input  logic ar_unit_busy_i,

  // Hit/Miss unit interface
  // -----------------------
  // Write descriptor
  output desc_t w_desc_o,
  output logic w_desc_valid_o,
  input  logic w_desc_ready_i,
  // Read descriptor
  output desc_t r_desc_o,
  output logic r_desc_valid_o,
  input  logic r_desc_ready_i,

  // R/W unit interface
  // ------------------
  // Group W/R/B data + valid/ready
  output axi_data_req_t req_o,
  input  axi_data_resp_t resp_i,

  // LLC Addr rule
  // --------------
  input rule_t cached_rule_i
);

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

// Internal signals
// ----------------
// AXI4 req and resp definition
localparam int unsigned AxiStrbWidthFull = AxiCfg.DataWidthFull / 32'd8;

// Need a master and a slave ID type, as the master ID is one bit wider 
typedef logic [AxiCfg.SlvPortIdWidth-1:0] axi_id_t;
typedef logic [AxiCfg.AddrWidthFull-1:0]  axi_addr_t;
typedef logic [AxiCfg.DataWidthFull-1:0]  axi_data_t;
typedef logic [AxiStrbWidthFull-1:0]      axi_strb_t;
typedef logic [AxiCfg.UserWidth-1:0]      axi_user_t;

// These macros are typedef of structs for the AXI channels.
`AXI_TYPEDEF_AW_CHAN_T(axi_aw_t, axi_addr_t, axi_id_t, axi_user_t)
`AXI_TYPEDEF_W_CHAN_T(axi_w_t, axi_data_t, axi_strb_t, axi_user_t)
`AXI_TYPEDEF_B_CHAN_T(axi_b_t, axi_id_t, axi_user_t)
`AXI_TYPEDEF_AR_CHAN_T(axi_ar_t, axi_addr_t, axi_id_t, axi_user_t)
`AXI_TYPEDEF_R_CHAN_T(axi_r_t, axi_data_t, axi_id_t, axi_user_t)

`AXI_TYPEDEF_REQ_T(axi_req_t, axi_aw_t, axi_w_t, axi_ar_t)
`AXI_TYPEDEF_RESP_T(axi_resp_t, axi_b_t, axi_r_t)

//`REG_BUS_TYPEDEF_ALL(conf, logic [31:0], logic [31:0], logic [3:0])

// DMA Read
arcane_obi_pkg::obi_req_t dma_read_obi_req;
arcane_obi_pkg::obi_resp_t dma_read_obi_resp;
axi_req_t dma_read_axi_req;
axi_resp_t dma_read_axi_resp;

// DMA Write
arcane_obi_pkg::obi_req_t dma_write_obi_req;
arcane_obi_pkg::obi_resp_t dma_write_obi_resp;
axi_req_t dma_write_axi_req;
axi_resp_t dma_write_axi_resp;


//-----------
// ARCANE Ctl
//-----------
// TODO: decide whether to have a single centralised one or a couple(?)
//assign llc_isolate_o = 1'b0; // TODO: this is a placeholder, should be set by the ARCANE control unit

axi_llc_arcane_fsm i_arcane_fsm (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .ecpu_lock_i(ecpu_llc_lock_i),
  .ecpu_lock_req_i(ecpu_llc_lock_req_i),
  .ready_lock_o(arcane_llc_lock_o),
  .llc_isolated_i(llc_isolated_i),
  .ar_unit_busy_i(ar_unit_busy_i),
  .aw_unit_busy_i(aw_unit_busy_i),
  .llc_isolate_o(llc_isolate_o)
);


//-------
// SW DMA
//-------
// TODO: missing sw dma
assign dma_read_obi_req ='0;
assign dma_write_obi_req ='0;

// TODO: check how req are treated when cache is not locked.
// Should have a HW mechanism thatt guarantees they are gated, so that mem cannot
// be compromised in those cases.


//-------------------
// OBI2AXI converters
//-------------------

// Read ch converter
// -----------------
core2axi_wrap #(
  .AXI4_ADDRESS_WIDTH(AxiCfg.AddrWidthFull),
  .AXI4_RDATA_WIDTH(AxiCfg.DataWidthFull), //64-bit
  .AXI4_WDATA_WIDTH(AxiCfg.DataWidthFull),
  .AXI4_ID_WIDTH(AxiCfg.SlvPortIdWidth),
  .AXI4_USER_WIDTH(AxiCfg.UserWidth),
  .axi_req_t(axi_req_t),
  .axi_resp_t(axi_resp_t),
  .obi_req_t(arcane_obi_pkg::obi_req_t),
  .obi_resp_t(arcane_obi_pkg::obi_resp_t)
) i_arcane_core2axi_r (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  // AXI slave interface
  .obi_req_i(dma_read_obi_req),
  .obi_resp_o(dma_read_obi_resp),
  .axi_req_o(dma_read_axi_req),
  .axi_resp_i(dma_read_axi_resp)
);


// Write ch converter
// ------------------
core2axi_wrap #(
  .AXI4_ADDRESS_WIDTH(AxiCfg.AddrWidthFull),
  .AXI4_RDATA_WIDTH(AxiCfg.DataWidthFull), //64-bit
  .AXI4_WDATA_WIDTH(AxiCfg.DataWidthFull),
  .AXI4_ID_WIDTH(AxiCfg.SlvPortIdWidth),
  .AXI4_USER_WIDTH(AxiCfg.UserWidth),
  .axi_req_t(axi_req_t),
  .axi_resp_t(axi_resp_t),
  .obi_req_t(arcane_obi_pkg::obi_req_t),
  .obi_resp_t(arcane_obi_pkg::obi_resp_t)
) i_arcane_core2axi_w (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  // AXI slave interface
  .obi_req_i(dma_write_obi_req),
  .obi_resp_o(dma_write_obi_resp),
  .axi_req_o(dma_write_axi_req),
  .axi_resp_i(dma_write_axi_resp)
);

//---------
// AXI2DESC
//---------

// Read ch converter
// -----------------
axi_llc_arcane_axi2desc #(
  .Cfg    ( Cfg      ),
  .AxiCfg ( AxiCfg   ),
  .chan_t ( axi_ar_t ),
  .Write  ( 1'b0     ), // Read channel
  .desc_t ( desc_t   ),
  .rule_t ( rule_t   )
) i_arcane_axi2desc_r (
  .clk_i,
  .rst_ni,
  .ax_chan_i(dma_read_axi_req.ar),
  .ax_chan_valid_i(dma_read_axi_req.ar_valid),
  .ax_chan_ready_o(dma_read_axi_resp.ar_ready),
  .src_dst_i(1'b1), // Read channel
  .desc_o(r_desc_o),
  .desc_valid_o(r_desc_valid_o),
  .desc_ready_i(r_desc_ready_i),
  .cached_rule_i(cached_rule_i)
);

// Write ch converter
// ------------------
axi_llc_arcane_axi2desc #(
  .Cfg    ( Cfg      ),
  .AxiCfg ( AxiCfg   ),
  .chan_t ( axi_aw_t ),
  .Write  ( 1'b1     ), // Write channel
  .desc_t ( desc_t   ),
  .rule_t ( rule_t   )
) i_arcane_axi2desc_w (
  .clk_i,
  .rst_ni,
  .ax_chan_i(dma_write_axi_req.aw),
  .ax_chan_valid_i(dma_write_axi_req.aw_valid),
  .ax_chan_ready_o(dma_write_axi_resp.aw_ready),
  .src_dst_i(1'b0), // Write channel
  .desc_o(w_desc_o),
  .desc_valid_o(w_desc_valid_o),
  .desc_ready_i(w_desc_ready_i),
  .cached_rule_i(cached_rule_i)
);

//------------
// Group R/W/B
//------------
// Just group all the signals according to the given types
// Req to R/W unit
assign req_o = axi_data_req_t'{
  w:        dma_write_axi_req.w,
  w_valid:  dma_write_axi_req.w_valid,
  b_ready:  dma_write_axi_req.b_ready,
  r_ready:  dma_read_axi_req.r_ready
};
// Resp from R/W unit
assign dma_read_axi_resp.r        = resp_i.r;
assign dma_read_axi_resp.r_valid  = resp_i.r_valid;
assign dma_read_axi_resp.b        = resp_i.b;
assign dma_read_axi_resp.b_valid  = resp_i.b_valid;
assign dma_write_axi_resp.w_ready = resp_i.w_ready;


endmodule