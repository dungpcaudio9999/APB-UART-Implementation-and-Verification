`ifndef APB_DEFINES_SV
`define APB_DEFINES_SV

// APB common parameters
`define APB_ADDR_WIDTH  12
`define APB_DATA_WIDTH 32

// Example register offsets
`define UART_REG_TXDATA   12'h000
`define UART_REG_RXDATA   12'h004
`define UART_REG_STATUS   12'h008
`define UART_REG_CONTROL  12'h00C

// Simple status bits
`define UART_STATUS_TX_EMPTY  0
`define UART_STATUS_RX_VALID  1

`endif

