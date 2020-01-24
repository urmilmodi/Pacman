# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog test.v rombackground.v

#load simulation using mux as the top level simulation module
vsim -L altera_mf_ver test

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

force {clk} 0 0ns , 1 {5ns} -r 10ns
# The first commands sets clk to after 0ns, then sets it to 1 after 5ns. This cycle repeats after 20ns.

force {KEY} 1111

run 10ns

force {KEY} 1110

run 70ns
