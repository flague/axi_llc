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
// File: axi_llc_status_tag_regs.hjson
// Author: Flavia Guella
// Date: 04/06/2025



{ name: "axi_llc_status_tag",
  clock_primary: "clk_i",
  reset_primary: "rst_ni",
  bus_interfaces: [
    { 
      protocol: "reg_iface", 
      direction: "device",
    },
  ],
  regwidth: "32",
  registers: [
  % for line in range(cache_num_lines):
    { 
      name:     "STATUS_${str(line)}",
      desc:     "Status register of cache line ${str(line)}",
      swaccess: "rw",
      hwaccess: "hrw",
      hwext:    "true",
      hwqe:     "true", // enable `qe` latched signal of software write pulse
      hwre:     "true",
      fields: [
        { 
          bits: "${cache_tag_width}+3:${cache_tag_width}", // 2 bits for status
          name: "CL_STATUS", 
          desc: "Contain the current status of the corresponding cache line\
                [0]: valid, [1]: dirty, [2]: cmpt",
        }
      ]
    },
    { name:     "TAG_${str(line)}",
      desc:     "Tag Address stored in cache line ${str(line)}",
      swaccess: "rw",
      hwaccess: "hrw",
      hwext:    "true",
      hwqe:     "true", // enable `qe` latched signal of software write pulse
      hwre:     "true",
      fields: [
        { bits: "${cache_tag_width}-1:0",
          name: "CL_TAG",
          desc: "Tag Address" 
        }
      ]
    },
  % endfor
  ]
}    