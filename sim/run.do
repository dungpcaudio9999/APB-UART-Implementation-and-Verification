# 1. Cleanup & Init Library
if [file exists work] {
    vdel -lib work -all
}
vlib work

# 2. Compile RTL
vlog -work work +cover=bcestf +incdir+../rtl ../rtl/uart.svp

# 3. Compile Testbench
# Include đủ các thư mục con
set INC_DIRS [list "+incdir+../tb/include" "+incdir+../tb/env" "+incdir+../tb/test" "+incdir+../tb/apb_agent" "+incdir+../tb/uart_agent"]

vlog -work work {*}$INC_DIRS ../tb/tb_top.sv

# 4. Check Arguments for Test Name
set TEST_LIST [list "test_sanity" "test_tx" "test_rx" "test_flow_control" "test_error_injection" "test_config_modes" "test_fifo" "test_full_regression"]

if { $argc > 0 } {
    if { $1 == "all" } {
        set RUN_LIST $TEST_LIST
    } else {
        set RUN_LIST [list $1]
    }
} else {
    # Mặc định chạy sanity nếu không nhập gì
    set RUN_LIST [list "test_sanity"]
}

# Create coverage directory if not exists
file mkdir coverage_db

# 5. Load Simulation & Run
foreach TESTNAME $RUN_LIST {
    puts "----------------------------------------------------------------"
    puts "Loading simulation with test: $TESTNAME"
    puts "----------------------------------------------------------------"
    
    # Load simulation
    # -voptargs=+acc: Để không bị tối ưu hóa mất tín hiệu (quan trọng để soi sóng)
    # -coverage: Enable coverage collection in simulation
    vsim -coverage -voptargs="+acc +cover=bcestf" tb_top +TESTNAME=$TESTNAME
    
    # Add wave window
    # Thêm tất cả tín hiệu trong tb_top
    add wave -position insertpoint sim:/tb_top/*
    # Thêm tín hiệu trong DUT để soi kỹ hơn
    add wave -group DUT sim:/tb_top/dut/*
    
    # Cấu hình định dạng Hex cho sóng
    radix -hex

    # Prevent $finish from quitting vsim
    onfinish stop

    # 6. Run
    run -all
    
    # Save coverage with explicit test name to ensure unique identity in merge
    coverage save -onexit -testname $TESTNAME coverage_db/${TESTNAME}.ucdb

    # Đóng simulation hiện tại để chuẩn bị cho vòng lặp tiếp theo
    quit -sim
}