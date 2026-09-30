onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib hdmi_tx_0_opt

do {wave.do}

view wave
view structure
view signals

do {hdmi_tx_0.udo}

run -all

quit -force
