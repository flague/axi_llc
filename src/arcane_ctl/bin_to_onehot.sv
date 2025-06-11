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
// File: bin_to_onehot.sv
// Author: Flavia Guella
// Date: 11/06/2025

module bin_to_onehot #(
    parameter int unsigned BIN_WIDTH = 16,
    // Do Not Change
    parameter int unsigned ONEHOT_WIDTH = BIN_WIDTH == 1 ? 1 : (1 << BIN_WIDTH)
) (
    input  logic [BIN_WIDTH-1:0] bin,
    output logic [ONEHOT_WIDTH-1:0] onehot
);

    always_comb begin
        onehot = '0;
        if (bin < ONEHOT_WIDTH) begin
            onehot[bin] = 1'b1;
        end
    end

`ifndef SYNTHESIS
`ifndef COMMON_CELLS_ASSERTS_OFF
  assert final ($onehot0(onehot)) else
    $fatal(1, "[onehot_to_bin] More than 1 bit set in the one-hot signal");
`endif
`endif
endmodule