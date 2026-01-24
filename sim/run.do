# Script chạy mô phỏng từ trong thư mục sim/
# Cách chạy: 
# 1. cd sim
# 2. vsim
# 3. do run.do

# 1. Cleanup & Init Library
if [file exists work] {
    vdel -lib work -all
}
vlib work

# 2. Compile RTL (Relative path ../rtl)
vlog -work work +incdir+../rtl ../rtl/uart.sv

# 3. Compile Testbench (Relative path ../tb)
# Include paths must also be relative
set INC_DIRS [list "+incdir+../tb/include" "+incdir+../tb/env" "+incdir+../tb/test" "+incdir+../tb/apb_agent" "+incdir+../tb/uart_agent"]

vlog -work work {*}$INC_DIRS ../tb/tb_top.sv

# 4. Check Arguments for Test Name
if { $argc > 0 } {
    set TESTNAME $1
} else {
    set TESTNAME "test_sanity"
}

# 5. Load Simulation
puts "Loading simulation with test: $TESTNAME"
vsim -voptargs="+acc" tb_top +TESTNAME=$TESTNAME

# 6. Run
run -all