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
// File: core2axi_wrap.sv
// Author: Flavia Guella
// Date: 11/06/2025

module core2axi_wrap #(
    parameter int unsigned AXI4_ADDRESS_WIDTH = 32,
    parameter int unsigned AXI4_RDATA_WIDTH   = 32,
    parameter int unsigned AXI4_WDATA_WIDTH   = 32,
    parameter int unsigned AXI4_ID_WIDTH      = 16,
    parameter int unsigned AXI4_USER_WIDTH    = 10,
    parameter string REGISTERED_GRANT         = "FALSE",        // "TRUE"|"FALSE"
    parameter type axi_req_t                  = logic,
    parameter type axi_resp_t                 = logic,
    parameter type obi_req_t                  = logic,
    parameter type obi_resp_t                 = logic
) (
  input logic clk_i,
  input logic rst_ni,
  
  // OBI interface
  // -------------
  input  obi_req_t  obi_req_i,          // OBI request
  output obi_resp_t obi_resp_o,         // OBI response

  // AXI4 interface
  // --------------
  output axi_req_t  axi_req_o,         // AXI request
  input  axi_resp_t axi_resp_i         // AXI response
);

//---------
// CORE2AXI
//---------
core2axi #(
  .AXI4_ADDRESS_WIDTH(AXI4_ADDRESS_WIDTH),
  .AXI4_RDATA_WIDTH(AXI4_RDATA_WIDTH),
  .AXI4_WDATA_WIDTH(AXI4_WDATA_WIDTH),
  .AXI4_ID_WIDTH(AXI4_ID_WIDTH),
  .AXI4_USER_WIDTH(AXI4_USER_WIDTH),
  .REGISTERED_GRANT(REGISTERED_GRANT)
) i_core2axi (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  // OBI interface
  .data_req_i(obi_req_i.req),
  .data_gnt_o(obi_resp_o.gnt),
  .data_rvalid_o(obi_resp_o.rvalid),
  .data_addr_i(obi_req_i.addr),
  .data_we_i(obi_req_i.we),
  .data_be_i(obi_req_i.be),
  .data_rdata_o(obi_resp_o.rdata),
  .data_wdata_i(obi_req_i.wdata),
  // AXI4 AW interface
  .aw_id_o(axi_req_o.aw.id),
  .aw_addr_o(axi_req_o.aw.addr),
  .aw_len_o(axi_req_o.aw.len),
  .aw_size_o(axi_req_o.aw.size),
  .aw_burst_o(axi_req_o.aw.burst),
  .aw_lock_o(axi_req_o.aw.lock),
  .aw_cache_o(axi_req_o.aw.cache),
  .aw_prot_o(axi_req_o.aw.prot),
  .aw_region_o(axi_req_o.aw.region),
  .aw_user_o(axi_req_o.aw.user),
  .aw_qos_o(axi_req_o.aw.qos),
  .aw_valid_o(axi_req_o.aw_valid),
  .aw_ready_i(axi_resp_i.aw_ready),
  // AXI4 W interface
  .w_data_o(axi_req_o.w.data),
  .w_strb_o(axi_req_o.w.strb),
  .w_last_o(axi_req_o.w.last),
  .w_user_o(axi_req_o.w.user),
  .w_valid_o(axi_req_o.w_valid),
  .w_ready_i(axi_resp_i.w_ready),
  // AXI4 B interface
  .b_id_i(axi_resp_i.b.id),
  .b_resp_i(axi_resp_i.b.resp),
  .b_user_i(axi_resp_i.b.user),
  .b_valid_i(axi_resp_i.b_valid),
  .b_ready_o(axi_req_o.b_ready),
  // AXI4 AR interface
  .ar_id_o(axi_req_o.ar.id),
  .ar_addr_o(axi_req_o.ar.addr),
  .ar_len_o(axi_req_o.ar.len),
  .ar_size_o(axi_req_o.ar.size),
  .ar_burst_o(axi_req_o.ar.burst),
  .ar_lock_o(axi_req_o.ar.lock),
  .ar_cache_o(axi_req_o.ar.cache),
  .ar_prot_o(axi_req_o.ar.prot),
  .ar_region_o(axi_req_o.ar.region),
  .ar_user_o(axi_req_o.ar.user),
  .ar_qos_o(axi_req_o.ar.qos),
  .ar_valid_o(axi_req_o.ar_valid),
  .ar_ready_i(axi_resp_i.ar_ready),
  // AXI4 R interface
  .r_id_i(axi_resp_i.r.id),
  .r_data_i(axi_resp_i.r.data),
  .r_resp_i(axi_resp_i.r.resp),
  .r_last_i(axi_resp_i.r.last),
  .r_user_i(axi_resp_i.r.user),
  .r_valid_i(axi_resp_i.r_valid),
  .r_ready_o(axi_req_o.r_ready)
);

endmodule