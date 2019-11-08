# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog main.v ram32x4.v

#load simulation using mux as the top level simulation module
vsim -L altera_mf_ver main

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

# force {clk} 0 0ns , 1 {5ns} -r 10ns
# The first commands sets clk to after 0ns, then sets it to 1 after 5ns. This cycle repeats after 10ns.

force {KEY[0]} 0 0ns , 1 {5ns} -r 10ns

# Reset State
force {SW[9]} 0
force {SW[3:0]} 0000
force {SW[8:4]} 0000
run 10ns

# Store 1111 into 0000
force {SW[9]} 1
force {SW[3:0]} 1111
force {SW[8:4]} 0000
run 10ns

# Store 0101 into 1111
force {SW[9]} 1
force {SW[3:0]} 0101
force {SW[8:4]} 1111
run 10ns

# Read 0000
force {SW[9]} 0
force {SW[3:0]} 0000
force {SW[8:4]} 0000
run 10ns

# Read 1111
force {SW[9]} 0
force {SW[3:0]} 0000
force {SW[8:4]} 1111
run 10ns

# Store 0000 into 1111
force {SW[9]} 1
force {SW[3:0]} 0000
force {SW[8:4]} 1111
run 10ns

# Store 0101 into 1010
force {SW[9]} 1
force {SW[3:0]} 0101
force {SW[8:4]} 1010
run 10ns

# Read 1111
force {SW[9]} 0
force {SW[3:0]} 0000
force {SW[8:4]} 1111
run 10ns

# Read 1010
force {SW[9]} 0
force {SW[3:0]} 0000
force {SW[8:4]} 1010
run 10ns