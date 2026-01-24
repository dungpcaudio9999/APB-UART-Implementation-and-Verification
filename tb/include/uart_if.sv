`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if(input logic clk);
  // Các tín hiệu theo Spec
  logic rx;
  logic tx;
  logic cts_n; // Clear to send (Input của DUT)
  logic rts_n; // Request to send (Output của DUT)

  // Clocking block cho Driver (Sửa tên thành cb_drv cho chuẩn)
  clocking cb_drv @(posedge clk);
    default input #1step output #1step;
    output rx, cts_n; // Driver lái tín hiệu này vào DUT
    input  tx, rts_n; // Driver đọc tín hiệu này từ DUT
  endclocking

  // Clocking block cho Monitor
  clocking cb_mon @(posedge clk);
    default input #1step output #1step;
    input rx, tx, cts_n, rts_n; // Monitor chỉ nhìn, không lái
  endclocking

  modport TB_DRV (clocking cb_drv);
  modport TB_MON (clocking cb_mon);
  modport DUT (input rx, cts_n, output tx, rts_n);

endinterface
`endif