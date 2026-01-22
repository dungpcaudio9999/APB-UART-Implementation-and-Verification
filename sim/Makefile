SIM     ?= vlog
VSIM    ?= vsim
TOP     ?= tb_top

RTL_DIR := ../rtl
TB_DIR  := ../tb

SRCS := \
  $(RTL_DIR)/uart.sv \
  $(TB_DIR)/include/apb_defines.sv \
  $(TB_DIR)/include/apb_if.sv \
  $(TB_DIR)/include/uart_if.sv \
  $(TB_DIR)/include/transaction.sv \
  $(TB_DIR)/apb_agent/apb_driver.sv \
  $(TB_DIR)/apb_agent/apb_monitor.sv \
  $(TB_DIR)/apb_agent/apb_generator.sv \
  $(TB_DIR)/uart_agent/uart_driver.sv \
  $(TB_DIR)/uart_agent/uart_monitor.sv \
  $(TB_DIR)/env/scoreboard.sv \
  $(TB_DIR)/env/coverage.sv \
  $(TB_DIR)/env/environment.sv \
  $(TB_DIR)/test/base_test.sv \
  $(TB_DIR)/test/test_sanity.sv \
  $(TB_DIR)/test/test_tx.sv \
  $(TB_DIR)/test/test_rx.sv \
  $(TB_DIR)/tb_top.sv

all: comp sim

comp:
	$(SIM) +acc -sv $(SRCS)

sim:
	$(VSIM) -c $(TOP) -do "run -all; quit"

clean:
	rm -rf work transcript vsim.wlf

