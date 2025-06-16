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
// File: axi_from_obi.sv
// Author: Flavia Guella
// Date: 16/06/2025
// From axi_from_mem.sv

`include "axi/typedef.svh"
//----
// Bridge between OBI and AXI
// Pass through AXI-lite for simplicity

//----

/// Protocol adapter which translates memory requests to the AXI4 protocol.
///
/// This module acts like an SRAM and makes AXI4 requests downstream.
///
/// Supports multiple outstanding requests and will have responses for reads **and** writes.
/// Response latency is not fixed and for sure **not 1** and depends on the AXI4 memory system.
/// The `mem_resp_valid_o` can have multiple cycles of latency from the corresponding `mem_gnt_o`.
module axi_from_obi #(
  // AXI parameters
  // --------------
  parameter int unsigned AXI4_ADDR_WIDTH   = 32,
  parameter int unsigned AXI4_RDATA_WIDTH  = 32,
  parameter int unsigned AXI4_WDATA_WIDTH  = 32,
  parameter int unsigned AXI4_ID_WIDTH     = 16,
  parameter int unsigned AXI4_USER_WIDTH   = 10,
  // OBI parameters
  // --------------
  parameter int unsigned OBI_ADDR_WIDTH    = 32,
  parameter int unsigned OBI_RDATA_WIDTH   = 32,
  parameter int unsigned OBI_WDATA_WIDTH   = 32,
  /// How many requests can be in flight at the same time. (Depth of the response mux FIFO).
  parameter int unsigned MAX_REQUESTS      = 8,
  /// Protection signal the module should emit on the AXI4 transactions.
  parameter axi_pkg::prot_t AxiProt         = 3'b000,
  // OBI request struct definition
  parameter type            obi_req_t      = logic,
  // OBI response struct definition
  parameter type            obi_resp_t     = logic,
  // AXI4 request struct definition
  parameter type            axi_req_t      = logic,
  // AXI4 response struct definition
  parameter type            axi_resp_t      = logic

)(
  input  logic clk_i,
  input  logic rst_ni,

  // OBI interface
  // -------------
  input  obi_req_t obi_req_i,          // OBI request
  output obi_resp_t obi_resp_o,        // OBI response

  // AXI interface
  // --------------
  output axi_req_t axi_req_o,         // AXI request
  input  axi_resp_t axi_resp_i           // AXI response
);
  `AXI_LITE_TYPEDEF_ALL(axi_lite, logic [AXI4_ADDR_WIDTH-1:0], logic [AXI4_WDATA_WIDTH-1:0], logic [AXI4_WDATA_WIDTH/8-1:0])
  axi_lite_req_t axi_lite_req;
  axi_lite_resp_t axi_lite_resp;

  axi_lite_from_obi #(
    .AXI4_ADDR_WIDTH ( AXI4_ADDR_WIDTH ),
    .AXI4_RDATA_WIDTH ( AXI4_RDATA_WIDTH),
    .AXI4_WDATA_WIDTH ( AXI4_WDATA_WIDTH),
    .OBI_ADDR_WIDTH  ( OBI_ADDR_WIDTH),
    .OBI_RDATA_WIDTH ( OBI_RDATA_WIDTH),
    .OBI_WDATA_WIDTH ( OBI_WDATA_WIDTH),
    .MAX_REQUESTS    ( MAX_REQUESTS    ),
    .AxiProt         ( AxiProt         ),
    .axi_req_t       ( axi_lite_req_t  ),
    .axi_resp_t       ( axi_lite_resp_t ),
    .obi_req_t       ( obi_req_t       ),
    .obi_resp_t      ( obi_resp_t      )
  ) i_axi_lite_from_obi (
    .clk_i,
    .rst_ni,
    .obi_req_i       ( obi_req_i       ),
    .obi_resp_o      ( obi_resp_o      ),
    .axi_req_o       ( axi_lite_req    ),
    .axi_resp_i       ( axi_lite_resp    )
  );

  axi_lite_to_axi #(
    .AxiDataWidth    ( AXI4_WDATA_WIDTH),
    .req_lite_t      ( axi_lite_req_t  ),
    .resp_lite_t     ( axi_lite_resp_t ),
    .axi_req_t       ( axi_req_t       ),
    .axi_resp_t      ( axi_resp_t       )
  ) i_axi_lite_to_axi (
    .slv_req_lite_i  ( axi_lite_req    ),
    .slv_resp_lite_o ( axi_lite_resp    ),
    .slv_aw_cache_i ('0), // TODO: check to what this should be connected
    .slv_ar_cache_i ('0), // TODO: check to what this should be connected 
    .mst_req_o       ( axi_req_o       ),
    .mst_resp_i      ( axi_resp_i       )
  );

endmodule
