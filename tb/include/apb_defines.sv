`ifndef APB_DEFINES_SV
`define APB_DEFINES_SV

// 1. APB Common Parameters
`define APB_ADDR_WIDTH  12
`define APB_DATA_WIDTH  32

// 2. Register Offsets
`define UART_REG_TXDATA   12'h000
`define UART_REG_RXDATA   12'h004
`define UART_REG_CONFIG   12'h008
`define UART_REG_CONTROL  12'h00C
`define UART_REG_STATUS   12'h010

// 3. Bit Definitions

// -- Config Register Bits (0x008)  --
`define CFG_DATA_BITS_MASK  2'b11  // Bits [1:0]
`define CFG_STOP_BIT_POS    2      // Bit [2]
`define CFG_PARITY_EN_POS   3      // Bit [3]
`define CFG_PARITY_TYPE_POS 4      // Bit [4]

// -- Control Register Bits (0x00C)  --
`define CTRL_START_TX_POS   0

// -- Status Register Bits (0x010)  --
`define STT_TX_DONE_POS     0      // Bit [0] - Báo gửi xong
`define STT_RX_DONE_POS     1      // Bit [1] - Báo có hàng mới
`define STT_PARITY_ERR_POS  2      // Bit [2] - Báo lỗi Parity

`endif