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
// File: axi_lite_from_obi.sv
// Author: Flavia Guella
// Date: 16/06/2025
// From axi_lite_from_mem.sv

//----------------------------------------
// Bridge between OBI and AXI lite
// TODO: support for outstanding not complete for different data widths
//----------------------------------------

module axi_lite_from_obi #(
  // AXI parameters
  // --------------
  parameter int unsigned AXI4_ADDR_WIDTH   = 32,
  parameter int unsigned AXI4_RDATA_WIDTH  = 32,
  parameter int unsigned AXI4_WDATA_WIDTH  = 32,
  parameter int unsigned AXI4_ID_WIDTH     = 16,
  // OBI parameters
  // --------------
  parameter int unsigned AXI4_USER_WIDTH   = 10,
  parameter int unsigned OBI_ADDR_WIDTH    = 32,
  parameter int unsigned OBI_RDATA_WIDTH   = 32,
  parameter int unsigned OBI_WDATA_WIDTH   = 32,
  // How many requests can be in flight at the same time. (Depth of the response mux FIFO).
  parameter int unsigned MAX_REQUESTS      = 8,
  // Protection signal the module should emit on the AXI4-Lite transactions.
  parameter axi_pkg::prot_t AxiProt = 3'b000,
  // OBI request struct definition
  parameter type            obi_req_t      = logic,
  // OBI response struct definition
  parameter type            obi_resp_t     = logic,
  // AXI4 request struct definition
  parameter type            axi_req_t      = logic,
  // AXI4 response struct definition
  parameter type            axi_resp_t      = logic,
  /// AXI4-Lite address type, derived from `AxiAddrWidth`.
  localparam type axi_addr_t = logic[AXI4_ADDR_WIDTH-1:0],
  // be width OBI
  localparam type obi_be_t = logic[OBI_WDATA_WIDTH/8-1:0],
  // strb width AXI4
  localparam type axi_strb_t = logic[AXI4_WDATA_WIDTH/8-1:0]
) (
  // Clock input, positive edge triggered
  input logic clk_i,
  // Asynchronous reset, active low
  input logic rst_ni,
  
  // OBI interface
  // -------------
  // OBI request input
  input obi_req_t obi_req_i,
  // OBI response output
  output obi_resp_t obi_resp_o,

  // AXI4-lite ports
  // ---------------------
  // AXI4-Lite request output
  output axi_req_t axi_req_o,
  // AXI4-Lite response input
  input axi_resp_t axi_resp_i
);
  `include "common_cells/registers.svh"

  // Response FIFO control signals.
  logic fifo_full, fifo_empty;
  // Bookkeeping for sent write beats.
  logic aw_sent_q, aw_sent_d;
  logic w_sent_q,  w_sent_d;
  // Sampled version of the address
  logic [AXI4_ADDR_WIDTH-1:0] req_addr_q;

  // Control for translating request to the AXI4-Lite `AW`, `W` and `AR` channels.
  always_comb begin
    // Default assignments.
    axi_req_o.aw       = '0;
    axi_req_o.aw.addr  = axi_addr_t'(obi_req_i.addr);
    axi_req_o.aw.prot  = AxiProt;
    axi_req_o.aw_valid = 1'b0;
    axi_req_o.w        = '0;
    // Manage AXI with higher data width
    if (AXI4_RDATA_WIDTH == OBI_RDATA_WIDTH) begin
      axi_req_o.w.data   = obi_req_i.wdata;
      axi_req_o.w.strb   = axi_strb_t'(obi_req_i.be);
    end else begin
      axi_req_o.w.data   = obi_req_i.addr[2] ? {obi_req_i.wdata, {(AXI4_RDATA_WIDTH-OBI_RDATA_WIDTH){1'b0}}} :
                                              { {(AXI4_RDATA_WIDTH-OBI_RDATA_WIDTH){1'b0}},  obi_req_i.wdata };
      axi_req_o.w.strb   = obi_req_i.addr[2] ? {obi_req_i.be, {(AXI4_RDATA_WIDTH/4-OBI_RDATA_WIDTH/4){1'b0}}} :
                                              axi_strb_t'(obi_req_i.be);
    end
    // Manage case in which OBI data width is lower than AXI4-Lite data width.
    axi_req_o.w_valid  = 1'b0;
    axi_req_o.ar       = '0;
    axi_req_o.ar.addr  = axi_addr_t'(obi_req_i.addr);
    axi_req_o.ar.prot  = AxiProt;
    axi_req_o.ar_valid = 1'b0;
    // This is also the push signal for the response FIFO.
    obi_resp_o.gnt          = 1'b0;
    // Bookkeeping about sent write channels.
    aw_sent_d          = aw_sent_q;
    w_sent_d           = w_sent_q;

    // Control for Request to AXI4-Lite translation.
    if (obi_req_i.req && !fifo_full) begin
      if (!obi_req_i.we) begin
        // It is a read request.
        axi_req_o.ar_valid = 1'b1;
        obi_resp_o.gnt     = axi_resp_i.ar_ready;
      end else begin
        // Is is a write request, decouple `AW` and `W` channels.
        unique case ({aw_sent_q, w_sent_q})
          2'b00 : begin
            // None of the AXI4-Lite writes have been sent jet.
            axi_req_o.aw_valid = 1'b1;
            axi_req_o.w_valid  = 1'b1;
            unique case ({axi_resp_i.aw_ready, axi_resp_i.w_ready})
              2'b01 : begin // W is sent, still needs AW.
                w_sent_d = 1'b1;
              end
              2'b10 : begin // AW is sent, still needs W.
                aw_sent_d = 1'b1;
              end
              2'b11 : begin // Both are transmitted, grant the write request.
                obi_resp_o.gnt = 1'b1;
              end
              default : /* do nothing */;
            endcase
          end
          2'b10 : begin
            // W has to be sent.
            axi_req_o.w_valid = 1'b1;
            if (axi_resp_i.w_ready) begin
              aw_sent_d = 1'b0;
              obi_resp_o.gnt = 1'b1;
            end
          end
          2'b01 : begin
            // AW has to be sent.
            axi_req_o.aw_valid = 1'b1;
            if (axi_resp_i.aw_ready) begin
              w_sent_d  = 1'b0;
              obi_resp_o.gnt = 1'b1;
            end
          end
          default : begin
            // Failsafe go to IDLE.
            aw_sent_d = 1'b0;
            w_sent_d  = 1'b0;
          end
        endcase
      end
    end
  end

  `FFARN(aw_sent_q, aw_sent_d, 1'b0, clk_i, rst_ni)
  `FFARN(w_sent_q, w_sent_d, 1'b0, clk_i, rst_ni)

  // Select which response should be forwarded. `1` write response, `0` read response.
  logic resp_sel;

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0        ), // No fallthrough for one cycle delay before ready on AXI.
    .DEPTH        ( MAX_REQUESTS),
    .dtype        ( logic       )
  ) i_fifo_resp_mux (
    .clk_i,
    .rst_ni,
    .flush_i    ( 1'b0            ),
    .testmode_i ( 1'b0            ),
    .full_o     ( fifo_full       ),
    .empty_o    ( fifo_empty      ),
    .usage_o    ( /*not used*/    ),
    .data_i     ( obi_req_i.we    ),
    .push_i     ( obi_resp_o.gnt  ),
    .data_o     ( resp_sel         ),
    .pop_i      ( obi_resp_o.rvalid)
  );

  // Response selection control.
  // If something is in the FIFO, the corresponding channel is ready.
  assign axi_req_o.b_ready = !fifo_empty &&  resp_sel;
  assign axi_req_o.r_ready = !fifo_empty && !resp_sel;
  // Read data is directly forwarded.
  always_comb begin
    if (AXI4_RDATA_WIDTH == OBI_RDATA_WIDTH) begin
      // 32-bit data width.
      // Use sampled req addr to select the upper or lower half of the data
      obi_resp_o.rdata = req_addr_q[2] ? axi_resp_i.r.data[AXI4_RDATA_WIDTH-1:OBI_RDATA_WIDTH] : axi_resp_i.r.data[OBI_RDATA_WIDTH-1:0];
    //(AXI4_RDATA_WIDTH == 64 && OBI_RDATA_WIDTH == 32) begin
    end else
      obi_resp_o.rdata = axi_resp_i.r.data[OBI_RDATA_WIDTH-1:0];
  end



  // Error is taken from the respective channel.
  // OBI does not support error
  // TODO: understand hot to handle this case
  //assign mem_resp_error_o = resp_sel ?
  //    (axi_resp_i.b.resp inside {axi_pkg::RESP_SLVERR, axi_pkg::RESP_DECERR}) :
  //    (axi_resp_i.r.resp inside {axi_pkg::RESP_SLVERR, axi_pkg::RESP_DECERR});
  // Response is valid if the handshaking on the respective channel occurs.
  // Can not happen at the same time as ready is set from the FIFO.
  // This serves as the pop signal for the FIFO.
  assign obi_resp_o.rvalid = (axi_resp_i.b_valid && axi_req_o.b_ready) ||
                             (axi_resp_i.r_valid && axi_req_o.r_ready);

  // Addr reg
  // --------
  // TODO: no support for outstanding in this way
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_addr_q <= '0;
    end else if (obi_req_i.req && obi_resp_o.gnt) begin
      // If request is granted, sample address
      req_addr_q <= obi_req_i.addr;
    end
  end


  // pragma translate_off
  `ifndef SYNTHESIS
  `ifndef VERILATOR
    initial begin : proc_assert
      assert (OBI_ADDR_WIDTH > 32'd0) else
          $fatal(1, "OBI_ADDR_WIDTH has to be greater than 0!");
      assert (AXI4_ADDR_WIDTH > 32'd0) else 
          $fatal(1, "AXI4_ADDR_WIDTH has to be greater than 0!");
      assert (AXI4_RDATA_WIDTH inside {32'd32, 32'd64}) else
          $fatal(1, "AXI4_RDATA_WIDTH has to be either 32 or 64 bit!");
      assert (AXI4_WDATA_WIDTH inside {32'd32, 32'd64}) else
          $fatal(1, "AXI4_WDATA_WIDTH has to be either 32 or 64 bit!");
      assert (OBI_RDATA_WIDTH inside {32'd32, 32'd64}) else
          $fatal(1, "OBI_RDATA_WIDTH has to be either 32 or 64 bit!");
      assert (OBI_WDATA_WIDTH inside {32'd32, 32'd64}) else
          $fatal(1, "OBI_WDATA_WIDTH has to be either 32 or 64 bit!");
      assert (MAX_REQUESTS > 32'd0) else 
          $fatal(1, "MAX_REQUESTS has to be greater than 0!");
      assert (AXI4_ADDR_WIDTH == $bits(axi_req_o.aw.addr)) else
          $fatal(1, "AxiAddrWidth has to match axi_req_o.aw.addr!");
      assert (AXI4_ADDR_WIDTH == $bits(axi_req_o.ar.addr)) else
          $fatal(1, "AxiAddrWidth has to match axi_req_o.ar.addr!");
      assert (AXI4_WDATA_WIDTH == $bits(axi_req_o.w.data)) else
          $fatal(1, "DataWidth has to match axi_req_o.w.data!");
      assert (AXI4_WDATA_WIDTH/8 == $bits(axi_req_o.w.strb)) else
          $fatal(1, "DataWidth / 8 has to match axi_req_o.w.strb!");
      assert (AXI4_RDATA_WIDTH == $bits(axi_resp_i.r.data)) else
          $fatal(1, "DataWidth has to match axi_resp_i.r.data!");
    end
    default disable iff (~rst_ni);
    assert property (@(posedge clk_i) (obi_req_i.req && !obi_resp_o.gnt) |=> obi_req_i.req) else
        $fatal(1, "It is not allowed to deassert the request if it was not granted!");
    assert property (@(posedge clk_i) (obi_req_i.req && !obi_resp_o.gnt) |=> $stable(obi_req_i.addr)) else
        $fatal(1, "obi_req_i.addr has to be stable if request is not granted!");
    assert property (@(posedge clk_i) (obi_req_i.req && !obi_resp_o.gnt) |=> $stable(obi_req_i.we)) else
        $fatal(1, "obi_req_i.we has to be stable if request is not granted!");
    assert property (@(posedge clk_i) (obi_req_i.req && !obi_resp_o.gnt) |=> $stable(obi_req_i.wdata)) else
        $fatal(1, "obi_req_i.wdata has to be stable if request is not granted!");
    assert property (@(posedge clk_i) (obi_req_i.req && !obi_resp_o.gnt) |=> $stable(obi_req_i.be)) else
        $fatal(1, "obi_req_i.be has to be stable if request is not granted!");
  `endif
  `endif
  // pragma translate_on
endmodule
