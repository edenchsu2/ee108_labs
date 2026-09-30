vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../../lab1.srcs/sources_1/ip/hdmi_tx_0/hdl/encode.v" \
"../../../../lab1.srcs/sources_1/ip/hdmi_tx_0/hdl/serdes_10_to_1.v" \
"../../../../lab1.srcs/sources_1/ip/hdmi_tx_0/hdl/srldelay.v" \
"../../../../lab1.srcs/sources_1/ip/hdmi_tx_0/hdl/hdmi_tx_v1_0.v" \
"../../../../lab1.srcs/sources_1/ip/hdmi_tx_0/sim/hdmi_tx_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

