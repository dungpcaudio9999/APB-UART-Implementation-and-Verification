# 1. Tạo thư viện làm việc
if [file exists work] {
    vdel -lib work -all
}
vlib work

# 2. Compile RTL (File thiết kế)
vlog -sv ../rtl/uart.sv

# 3. Compile Testbench
# Lưu ý: Viết +incdir+ liền mạch, không dùng biến để tránh lỗi khoảng trắng
vlog -sv \
    +incdir+../tb/include \
    +incdir+../tb/apb_agent \
    +incdir+../tb/uart_agent \
    +incdir+../tb/env \
    +incdir+../tb/test \
    ../tb/tb_top.sv

# 4. Khởi động mô phỏng
vsim -voptargs=+acc work.tb_top

# 5. Add wave
add wave -position insertpoint sim:/tb_top/*

# 6. Chạy
run -all
wave zoom full