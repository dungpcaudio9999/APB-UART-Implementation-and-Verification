
////////////////////////////////////////////////////////////////////////////////
//
//  Module Name:  apb.v
//  Project:      APB-UART
//  Author:       DungPC
//  Date:         01/2026
//  Description:  Description here...
//
////////////////////////////////////////////////////////////////////////////////

module apb (clk, reset_n, pclk, preset_n, psel, penable, pwrite, pstrb, paddr, pwdata, rx_data, tx_done, parity_error, pslverr, prdata, pready, tx_data, data_bit_num, stop_bit_num, parity_en, parity_type, start_tx);
input clk, reset_n;
input pclk, preset_n, psel, penable, pwrite;
input [3:0] pstrb;
input [11:0] paddr;
input [31:0] pwdata;
input rx_data, tx_done, rx_done, parity_error;

endmodule