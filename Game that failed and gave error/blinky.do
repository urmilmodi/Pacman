# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog Blinky.v Helper.v LeftRightData.v LeftRightDownData.v clearRom.v

#load simulation using mux as the top level simulation module
vsim -L altera_mf_ver Blinky

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

force {sysclk} 0 0ns , 1 {5ns} -r 10ns
# The first commands sets clk to after 0ns, then sets it to 1 after 5ns. This cycle repeats after 20ns.

# Force Direction via Rotation in Chase Mode
# Expected newFacing 1111111100000000
# Expected newLocation 0000110000001110
force {pacloc} 0000111100001111
force {pacfacing} 1111111100000000
force {currentloc} 0000111000001110
force {currentfacing} 0000000100000000
force {mode} 1000
force {rotate} 1
force {update} 1
run 80ns

# Chase Mode
# Expected newFacing 0000000000000001
# Expected newLocation 0000110000001111
# Therefore it takes bext path towards Pacman
force {pacloc} 0000111100001111
force {pacfacing} 1111111100000000
force {currentloc} 0000111000001110
force {currentfacing} 0000000100000000
force {mode} 1000
force {rotate} 0
force {update} 1
run 80ns


# Scatter Mode
# Goes towards top right corner (1101100000000000)
# Target should be 10000101100000000
# Based on Target Selection it can be assumed the best path is taken based on the Chase Mode Success
force {pacloc} 0000111100001111
force {pacfacing} 1111111100000000
force {currentloc} 0000111000001110
force {currentfacing} 0000000100000000
force {mode} 0100
force {rotate} 0
force {update} 1
run 80ns

# Frightened Mode
# Random Directions
force {pacloc} 0000111100001111
force {pacfacing} 1111111100000000
force {currentloc} 0000111000001110
force {currentfacing} 0000000100000000
force {mode} 0010
force {rotate} 0
force {update} 1
run 320ns

# Eaten Mode doesn't need to be shown because it follows similar implementation to Scatter Mode, simply the Target Location is different