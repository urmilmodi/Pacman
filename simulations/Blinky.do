# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog ../src/Blinky.v

#load simulation using mux as the top level simulation module
vsim Blinky

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

#force {clk} 0 0ns , 1 {5ns} -r 10ns
# The first commands sets clk to after 0ns, then sets it to 1 after 5ns. This cycle repeats after 20ns.

force {pacloc} 0000111100001111
force {currentloc} 0000111000001111
force {mode} 1000
force {rotate} 0
force {update} 0
force {currentfacing} 0000000100000000
run 10ns

force {rotate} 1
run 10ns

force {update} 1
run 10ns

force {update} 0
run 10ns

force {currentfacing} 1111111100000000
force {currentloc} 0000110100001111
force {rotate} 0
force {update} 1
run 10ns

force {update} 0
run 10ns


# Scatter State Test
force {currentloc} 0000111000001111
force {currentfacing} 0000000100000000
force {mode} 0100
force {rotate} 1
force {update} 1
run 10ns

force {update} 0
run 10ns

force {rotate} 0
force {currentfacing} 1111111100000000
force {currentloc} 0000110100001111
force {update} 1
run 10ns

force {update} 0
run 10ns

force {currentfacing} 0000000000000001
force {currentloc} 0000110100010000
force {update} 1
run 10ns

force {update} 0
run 10ns
