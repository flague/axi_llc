log -r /*

add wave -noupdate -color {light blue} -label Clock /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/clk_i
add wave -noupdate -color orange -label Reset /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/rst_ni
add wave -noupdate -divider {AXI SLV}
add wave -noupdate -color pink -label AXI_SLV_REQ /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/slv_req_i
add wave -noupdate -color pink -label AXI_SLV_RESP /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/slv_resp_o
add wave -noupdate -divider {AXI MST}
add wave -noupdate -label AXI_MST_REQ /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/mst_req_o
add wave -noupdate -label AXI_MST_RESP /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/mst_resp_i
add wave -noupdate -divider {REG CFG}
add wave -noupdate -label REG_CFG_REQ /tb_axi_llc/i_axi_llc_dut/conf_req_i
add wave -noupdate -label REG_CFG_RSP /tb_axi_llc/i_axi_llc_dut/conf_resp_o
add wave -noupdate -divider DESC
add wave -noupdate -label rw_desc /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/rw_desc
add wave -noupdate -label rw_desc_valid /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/rw_desc_valid
add wave -noupdate -label rw_desc_ready /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/rw_desc_ready
add wave -noupdate -divider DESC
add wave -noupdate -label desc /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/desc
add wave -noupdate -label hit_valid /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/hit_valid
add wave -noupdate -label hit_ready /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/hit_ready
add wave -noupdate -label miss_valid /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/miss_valid
add wave -noupdate -label miss_ready /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/miss_ready
add wave -noupdate -divider RAM
add wave -noupdate -label way_inp /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/to_way
add wave -noupdate -label way_inp_valid /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/to_way_valid
add wave -noupdate -label way_inp_ready /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/to_way_ready
add wave -noupdate -label evict_way_out /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/evict_way_out
add wave -noupdate -label evict_way_out_valid /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/evict_way_out_valid
add wave -noupdate -label read_way_out /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/read_way_out
add wave -noupdate -label read_way_out_valid /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/read_way_out_valid
add wave -noupdate -divider {RAM CONTENT}
add wave -noupdate -label inp_valid_dist /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_llc_ways/way_inp_valid
add wave -noupdate -label out_dist /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_llc_ways/way_out
add wave -noupdate -divider {ARCANE CTRL}
add wave -noupdate -label dma_reg_req_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_reg_req_i
add wave -noupdate -label dma_reg_rsp_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_reg_rsp_o
add wave -noupdate -label ecpu_src_dst_alloc_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/ecpu_src_dst_alloc_i
add wave -noupdate -label ecpu_llc_lock_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/ecpu_llc_lock_i
add wave -noupdate -label ecpu_llc_lock_req_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/ecpu_llc_lock_req_i
add wave -noupdate -label arcane_llc_lock_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/arcane_llc_lock_o
add wave -noupdate -label llc_isolate_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/llc_isolate_o
add wave -noupdate -label llc_isololated_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/llc_isolated_i
add wave -noupdate -label aw_unit_busy_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/aw_unit_busy_i
add wave -noupdate -label ar_unit_busy_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/ar_unit_busy_i
add wave -noupdate -label w_desc_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/w_desc_o
add wave -noupdate -label w_desc_valid_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/w_desc_valid_o
add wave -noupdate -label w_desc_ready_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/w_desc_ready_i
add wave -noupdate -label r_desc_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/r_desc_o
add wave -noupdate -label r_desc_valid_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/r_desc_valid_o
add wave -noupdate -label r_desc_ready_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/r_desc_ready_i
add wave -noupdate -label req_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/req_o
add wave -noupdate -label resp_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/resp_i
add wave -noupdate -label cached_rule_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/cached_rule_i
add wave -noupdate -label dma_read_obi_req /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_read_obi_req
add wave -noupdate -label dma_read_obi_resp /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_read_obi_resp
add wave -noupdate -label dma_read_axi_req /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_read_axi_req
add wave -noupdate -label dma_read_axi_resp /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_read_axi_resp
add wave -noupdate -label dma_write_obi_req /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_write_obi_req
add wave -noupdate -label dma_write_obi_resp /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_write_obi_resp
add wave -noupdate -label dma_write_axi_req /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_write_axi_req
add wave -noupdate -label dma_write_axi_resp /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/dma_write_axi_resp
add wave -noupdate -label ecpu_llc_lock_req_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/ecpu_llc_lock_req_i
add wave -noupdate -divider {ARCANE FSM}
add wave -noupdate -label curr_state /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/curr_state
add wave -noupdate -label next_state /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/next_state
add wave -noupdate -label clk_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/clk_i
add wave -noupdate -label rst_ni /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/rst_ni
add wave -noupdate -label ecpu_lock_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/ecpu_lock_i
add wave -noupdate -label ecpu_lock_req_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/ecpu_lock_req_i
add wave -noupdate -label ready_lock_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/ready_lock_o
add wave -noupdate -label llc_isolated_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/llc_isolated_i
add wave -noupdate -label ar_unit_busy_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/ar_unit_busy_i
add wave -noupdate -label aw_unit_busy_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/aw_unit_busy_i
add wave -noupdate -label llc_isolate_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_llc_arcane_ctl/i_arcane_fsm/llc_isolate_o
add wave -noupdate -divider Isolate
add wave -noupdate -label isolate_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/isolate_i
add wave -noupdate -label isolated_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/isolated_o
add wave -noupdate -label conf_regs_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_llc_config/conf_regs_i
add wave -noupdate -label conf_regs_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_llc_config/conf_regs_o
add wave -noupdate -label config_lock_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_llc_config/spm_lock_o
add wave -noupdate -label config_flush_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_llc_config/flushed_o
add wave -noupdate -label is_slv_req_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/slv_req_i
add wave -noupdate -label is_slv_rsp_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/slv_resp_o
add wave -noupdate -label is_mst_req_i /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/mst_req_o
add wave -noupdate -label is_mst_rsp_o /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/mst_resp_i
add wave -noupdate -label is_state_aw_d /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/state_aw_d
add wave -noupdate -label is_state_aw_q /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/state_aw_q
add wave -noupdate -label is_state_ar_d /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/state_ar_d
add wave -noupdate -label is_state_ar_q /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/state_ar_q
add wave -noupdate -label is_pending_aw_d /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_aw_d
add wave -noupdate -label is_pending_aw_q /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_aw_q
add wave -noupdate -label is_pending_w_d /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_w_d
add wave -noupdate -label is_pending_w_q /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_w_q
add wave -noupdate -label is_pending_ar_d /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_ar_d
add wave -noupdate -label is_pending_ar_q /tb_axi_llc/i_axi_llc_dut/i_axi_llc_top_raw/i_axi_isolate_flush/i_axi_isolate/pending_ar_q
